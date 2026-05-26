"""
Voice AI Agent — FastAPI Endpoints
────────────────────────────────────
POST /api/v1/voice/chat
    Main voice query endpoint.  Accepts a transcribed spoken query and returns
    a short, TTS-friendly natural language answer plus retrieved menu items.
    Supports multi-turn conversation via session_id.

POST /api/v1/voice/session
    Create a new session or clear an existing one.

GET  /api/v1/voice/session/{session_id}
    Inspect a session (history, context) — useful for debugging / the frontend.

DELETE /api/v1/voice/session/{session_id}
    Explicitly destroy a session (e.g., when user closes the voice screen).
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.voice.voice_rag import get_voice_rag_service
from app.services.voice.voice_session import get_session_store

router = APIRouter()


# ── Request / Response Schemas ────────────────────────────────────────────────

class VoiceChatRequest(BaseModel):
    """Body for POST /voice/chat"""
    query: str = Field(
        ...,
        min_length=1,
        max_length=500,
        description="The user's spoken query, already transcribed to text by the device STT.",
        example="I want something healthy and veg under 200 rupees",
    )
    session_id: Optional[str] = Field(
        None,
        description="Session UUID from a previous response. Omit (or pass null) to start a new session.",
    )
    area_name: Optional[str] = Field(
        None,
        description="User's current area / city (e.g. 'Nagpur'). Persisted in the session.",
        example="Nagpur",
    )
    restaurant_id: Optional[str] = Field(
        None,
        description="Optional UUID — restrict search to a single restaurant.",
    )


class VoiceMenuItem(BaseModel):
    """A single menu item returned by the RAG pipeline."""
    item_name:       str
    restaurant_name: str
    section_name:    Optional[str]
    price:           Optional[int]
    is_veg:          Optional[bool]
    calories:        Optional[int]
    health_score:    Optional[int]
    similarity:      Optional[float]


class VoiceChatResponse(BaseModel):
    """Response for POST /voice/chat"""
    answer:       str = Field(..., description="Short, TTS-ready conversational answer (2-3 sentences).")
    session_id:   str = Field(..., description="Pass this back on the next request to maintain context.")
    items:        List[Dict[str, Any]] = Field(default_factory=list, description="Top retrieved menu items.")
    filters_used: Dict[str, Any]       = Field(default_factory=dict, description="Extracted search filters.")


class SessionCreateRequest(BaseModel):
    """Body for POST /voice/session"""
    area_name:     Optional[str] = None
    restaurant_id: Optional[str] = None


class SessionInfo(BaseModel):
    """Session metadata (no history content for privacy)."""
    session_id:    str
    area_name:     str
    restaurant_id: Optional[str]
    turn_count:    int
    created_at:    str
    last_used:     str


class SessionHistoryTurn(BaseModel):
    role:    str
    content: str


class SessionDetailResponse(BaseModel):
    """Full session detail including conversation history."""
    session_id:   str
    area_name:    str
    restaurant_id: Optional[str]
    turn_count:   int
    history:      List[SessionHistoryTurn]


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post(
    "/chat",
    response_model=VoiceChatResponse,
    summary="Voice AI chat — TTS-optimized food discovery",
    description=(
        "Send a transcribed voice query. Returns a short, spoken-aloud-friendly answer "
        "and retrieved menu items. Use session_id to maintain multi-turn conversations."
    ),
)
async def voice_chat(req: VoiceChatRequest):
    """
    Main Voice AI Agent endpoint.

    **Flow:**
    1. Get or create a conversation session (for multi-turn context).
    2. Parse the query into structured filters (price, veg, health).
    3. Run hybrid semantic + SQL search against the menu database.
    4. Generate a short, TTS-friendly answer via Qwen LLM (or rule-based fallback).
    5. Persist the turn in the session history.
    6. Return `answer` (speak this!) + `session_id` + retrieved `items`.
    """
    if not req.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty.")

    svc = get_voice_rag_service()

    try:
        result = svc.chat(
            query=req.query.strip(),
            session_id=req.session_id,
            area_name=req.area_name or "",
            restaurant_id=req.restaurant_id,
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Voice AI service error: {str(e)}",
        )

    return VoiceChatResponse(
        answer=result["answer"],
        session_id=result["session_id"],
        items=result["items"],
        filters_used=result["filters_used"],
    )


@router.post(
    "/session",
    response_model=SessionInfo,
    summary="Create a new voice session",
    description="Create a brand-new conversation session. Returns session_id to use in /voice/chat.",
    status_code=201,
)
async def create_session(req: SessionCreateRequest):
    """
    Create a fresh voice session (e.g., when the user opens the Voice Agent screen).
    You can pre-set the area and restaurant context here.
    """
    store = get_session_store()
    session = store.get_or_create(session_id=None)  # always creates new

    if req.area_name or req.restaurant_id:
        session.set_context(
            area_name=req.area_name or "",
            restaurant_id=req.restaurant_id,
        )

    return SessionInfo(**session.to_dict())


@router.get(
    "/session/{session_id}",
    response_model=SessionDetailResponse,
    summary="Get session details",
    description="Retrieve the conversation history and context for a session. Useful for debugging.",
)
async def get_session(session_id: str):
    """
    Return full session info including conversation history.
    Returns 404 if the session does not exist or has expired.
    """
    store = get_session_store()
    session = store.get(session_id)
    if session is None:
        raise HTTPException(
            status_code=404,
            detail=f"Session '{session_id}' not found or has expired.",
        )

    history_turns = [
        SessionHistoryTurn(role=t["role"], content=t["content"])
        for t in session.get_history(max_turns=20)
    ]

    return SessionDetailResponse(
        session_id=session.session_id,
        area_name=session.area_name,
        restaurant_id=session.restaurant_id,
        turn_count=len(session.history) // 2,
        history=history_turns,
    )


@router.delete(
    "/session/{session_id}",
    summary="End a voice session",
    description="Explicitly destroy a session and its history (e.g., when user dismisses the Voice Agent screen).",
    status_code=200,
)
async def delete_session(session_id: str):
    """
    Delete a session. Safe to call even if the session doesn't exist.
    """
    store = get_session_store()
    store.delete(session_id)
    return {"detail": f"Session '{session_id}' ended."}


@router.post(
    "/session/{session_id}/clear",
    summary="Clear session history",
    description="Keep the session alive but wipe conversation history (e.g., 'start over' button).",
)
async def clear_session(session_id: str):
    """
    Clear conversation history of an existing session without destroying it.
    Returns 404 if the session is not found or expired.
    """
    store = get_session_store()
    session = store.get(session_id)
    if session is None:
        raise HTTPException(
            status_code=404,
            detail=f"Session '{session_id}' not found or has expired.",
        )
    session.clear()
    return {"detail": "Session history cleared.", "session_id": session_id}
