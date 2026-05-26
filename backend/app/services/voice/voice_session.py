"""
Voice Session Manager
─────────────────────
Manages per-user conversation sessions for the Voice AI Agent.

Each session stores:
  - conversation_history: list of {role, content} turns (for multi-turn LLM context)
  - area_name:            last known user area
  - restaurant_id:        last restaurant context
  - created_at / last_used: for TTL expiry

Sessions are stored in-memory by default.
For production, swap _SessionStore with a Redis-backed implementation.

Usage:
    store = get_session_store()
    session = store.get_or_create("some-uuid")
    session.add_turn("user", "I want healthy food")
    session.add_turn("assistant", "Here are some great options near Nagpur…")
    history = session.get_history(max_turns=6)
"""

from __future__ import annotations

import uuid
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any

logger = logging.getLogger(__name__)

# ── Session TTL ───────────────────────────────────────────────────────────────
SESSION_TTL_MINUTES = 30
MAX_HISTORY_TURNS   = 10   # cap stored turns per session to avoid huge prompts


# ── Single Session ────────────────────────────────────────────────────────────

class VoiceSession:
    """
    Holds the state for one user's voice conversation.
    """

    def __init__(self, session_id: str):
        self.session_id: str = session_id
        self.history: List[Dict[str, str]] = []   # [{role, content}, …]
        self.area_name: str = ""
        self.restaurant_id: Optional[str] = None
        self.created_at: datetime = datetime.utcnow()
        self.last_used: datetime = datetime.utcnow()

    # ── History management ────────────────────────────────────────────────────

    def add_turn(self, role: str, content: str) -> None:
        """
        Add a single dialogue turn.
        role must be 'user' or 'assistant'.
        """
        self.history.append({"role": role, "content": content})
        # Keep only the last MAX_HISTORY_TURNS to avoid token bloat
        if len(self.history) > MAX_HISTORY_TURNS * 2:
            self.history = self.history[-(MAX_HISTORY_TURNS * 2):]
        self._touch()

    def get_history(self, max_turns: int = 6) -> List[Dict[str, str]]:
        """
        Return the last `max_turns` dialogue pairs (user + assistant),
        ready to inject into the LLM messages list.
        """
        # Each "turn" = 1 user msg + 1 assistant msg (2 entries)
        limit = max_turns * 2
        return self.history[-limit:] if len(self.history) > limit else list(self.history)

    def set_context(self, area_name: str = "", restaurant_id: Optional[str] = None) -> None:
        """Update location/restaurant context for the session."""
        if area_name:
            self.area_name = area_name
        if restaurant_id is not None:
            self.restaurant_id = restaurant_id
        self._touch()

    def clear(self) -> None:
        """Reset history but keep the session alive."""
        self.history = []
        self._touch()

    def _touch(self) -> None:
        self.last_used = datetime.utcnow()

    @property
    def is_expired(self) -> bool:
        return datetime.utcnow() - self.last_used > timedelta(minutes=SESSION_TTL_MINUTES)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "session_id":    self.session_id,
            "area_name":     self.area_name,
            "restaurant_id": self.restaurant_id,
            "turn_count":    len(self.history) // 2,
            "created_at":    self.created_at.isoformat(),
            "last_used":     self.last_used.isoformat(),
        }


# ── Session Store ─────────────────────────────────────────────────────────────

class _SessionStore:
    """
    In-memory session store with lazy TTL cleanup.
    Thread-safe enough for single-process uvicorn workers.
    For multi-worker deployments, replace with Redis.
    """

    def __init__(self):
        self._sessions: Dict[str, VoiceSession] = {}

    def get_or_create(self, session_id: Optional[str] = None) -> VoiceSession:
        """
        Return existing (non-expired) session, or create a new one.
        If session_id is None or the session is expired, a fresh session is created.
        Returns the VoiceSession object.
        """
        self._cleanup()

        if session_id and session_id in self._sessions:
            session = self._sessions[session_id]
            if not session.is_expired:
                session._touch()
                return session
            else:
                logger.info(f"Voice session {session_id} expired — creating new session.")

        # Create brand-new session
        new_id = session_id if session_id else str(uuid.uuid4())
        session = VoiceSession(session_id=new_id)
        self._sessions[new_id] = session
        logger.info(f"Voice session created: {new_id}")
        return session

    def get(self, session_id: str) -> Optional[VoiceSession]:
        """Return a session by ID if it exists and is not expired."""
        session = self._sessions.get(session_id)
        if session and not session.is_expired:
            return session
        return None

    def delete(self, session_id: str) -> None:
        """Remove a session explicitly."""
        self._sessions.pop(session_id, None)

    def _cleanup(self) -> None:
        """Remove expired sessions (called on every get_or_create)."""
        expired = [sid for sid, s in self._sessions.items() if s.is_expired]
        for sid in expired:
            del self._sessions[sid]
        if expired:
            logger.debug(f"Cleaned up {len(expired)} expired voice session(s).")

    @property
    def active_count(self) -> int:
        return sum(1 for s in self._sessions.values() if not s.is_expired)


# ── Singleton ─────────────────────────────────────────────────────────────────

_store: Optional[_SessionStore] = None


def get_session_store() -> _SessionStore:
    """Return the global session store (created once per process)."""
    global _store
    if _store is None:
        _store = _SessionStore()
    return _store
