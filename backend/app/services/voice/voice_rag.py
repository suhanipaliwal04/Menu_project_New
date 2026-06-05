"""
Voice RAG Service
─────────────────
Voice-optimized wrapper around the existing RAGService.

Key differences from the base RAGService:
  1. Voice-friendly system prompt — short (2-3 sentences), no bullet points,
     warm conversational tone suitable for Text-to-Speech playback.
  2. Conversation history injection — previous turns are prepended to the
     LLM messages so the assistant can refer back ("As I mentioned…").
  3. Returns session_id alongside the usual answer + items.

Usage:
    svc = get_voice_rag_service()
    result = svc.chat(
        query="healthy veg food under 200",
        session_id="<uuid>",          # optional; creates new session if None
        area_name="Nagpur",
        restaurant_id=None,
    )
    # result = {
    #   "answer":       "Great choice! Near Nagpur, …",
    #   "session_id":   "<uuid>",
    #   "items":        [...],
    #   "filters_used": {...},
    # }
"""

from __future__ import annotations

import logging
from typing import Dict, Any, List, Optional

from app.core.config import settings
from app.services.nlp.query_parser import get_query_parser
from app.services.nlp.embedding_service import get_embedding_service
from app.services.voice.voice_session import get_session_store, VoiceSession

logger = logging.getLogger(__name__)


# ── Voice-specific prompt constants ──────────────────────────────────────────

_VOICE_SYSTEM_MSG = (
    "You are a friendly voice assistant for a restaurant discovery app. "
    "The user is speaking to you and your reply will be read aloud by text-to-speech, "
    "so it must sound natural when spoken. "
    "IMPORTANT RULES: "
    "1. Write exactly 1-2 short sentences — no more. "
    "2. NO bullet points, NO numbering, NO markdown formatting. "
    "3. Mention the restaurant name, item name, and price in a natural way. "
    "4. Sound warm and helpful, like a knowledgeable friend. "
    "5. Never invent items or prices that are not in the provided menu data. "
    "6. If the conversation history is provided, reference it naturally when relevant."
)

# Max conversation history turns to include in the LLM context
_MAX_HISTORY_TURNS = 4

# Hard vs soft filter split (same as base RAGService)
_HARD_FILTER_KEYS = {"is_veg", "max_price", "min_price"}
_SOFT_FILTER_KEYS = {"section_name", "min_health_score", "max_calories"}


class VoiceRAGService:
    """
    Voice-optimized RAG pipeline with conversation session support.
    """

    def __init__(self, top_k: int = 10):
        self.top_k  = top_k
        self.parser = get_query_parser()
        self._store = get_session_store()
        self._groq_client = None

    # ── Public API ─────────────────────────────────────────────────────────────

    def chat(self,
             query:         str,
             session_id:    Optional[str] = None,
             area_name:     str = "",
             restaurant_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Answer a natural language voice query.

        Args:
            query:         The user's spoken query (already transcribed to text).
            session_id:    Optional session UUID for conversation continuity.
            area_name:     User's location (area/city) to scope the search.
            restaurant_id: Optional — restrict search to a single restaurant.

        Returns:
            {
              "answer":       str,         # TTS-ready conversational answer
              "session_id":   str,         # Use this in the next request
              "items":        List[dict],  # Retrieved menu items
              "filters_used": dict,        # Parsed search filters
            }
        """
        # ── 1. Get / create session ──────────────────────────────────────────
        session = self._store.get_or_create(session_id)
        session.set_context(area_name=area_name, restaurant_id=restaurant_id)

        # ── 2. Parse query → structured filters ──────────────────────────────
        filters = self.parser.parse(query)
        logger.info(f"VoiceRAG [{session.session_id}]: filters = {filters}")

        # ── 3. Vector + SQL hybrid search ────────────────────────────────────
        hard_filters = {k: v for k, v in filters.items()
                        if k in _HARD_FILTER_KEYS and v is not None}
        hard_filters["semantic_query"] = filters.get("semantic_query", query)

        effective_area = area_name or session.area_name or ""
        effective_rid  = restaurant_id or session.restaurant_id
        restaurant_ids = [effective_rid] if effective_rid else None

        svc = get_embedding_service()
        items = svc.hybrid_search(
                query=query,
                filters=hard_filters,
                top_k=self.top_k,
                restaurant_ids=restaurant_ids,
                area_name=effective_area or None,
            )

        # ── 4. Generate voice-friendly answer ────────────────────────────────
        if not items:
            answer = (
                "I couldn't find anything matching that near you right now. "
                "Try asking for something else or a different area!"
            )
        else:
            soft_hints = {k: filters.get(k) for k in _SOFT_FILTER_KEYS}
            conversation_history = session.get_history(max_turns=_MAX_HISTORY_TURNS)
            answer = self._generate_voice_answer(
                query=query,
                items=items,
                area_name=effective_area,
                soft_hints=soft_hints,
                history=conversation_history,
            )

        # ── 5. Persist turns in session history ──────────────────────────────
        session.add_turn("user", query)
        session.add_turn("assistant", answer)

        logger.info(f"VoiceRAG [{session.session_id}]: {len(items)} items returned.")

        return {
            "answer":       answer,
            "session_id":   session.session_id,
            "items":        items,
            "filters_used": filters,
        }

    # ── LLM generation ─────────────────────────────────────────────────────────

    def _generate_voice_answer(self,
                               query:     str,
                               items:     List[Dict[str, Any]],
                               area_name: str,
                               soft_hints: Optional[Dict[str, Any]] = None,
                               history:   Optional[List[Dict[str, str]]] = None) -> str:
        """Generate a short, TTS-friendly answer using the Qwen LLM."""

        soft_hints = soft_hints or {}
        history    = history    or []

        # Format top items as clean lines
        item_lines = []
        for i, it in enumerate(items[:8], 1):
            veg_tag = "Veg" if it.get("is_veg") else "Non-Veg"
            cal     = f"{it['calories']} kcal" if it.get("calories") else ""
            hs      = f"health {it['health_score']}/10" if it.get("health_score") else ""
            rest    = it.get("restaurant_name", "Unknown Restaurant")
            extras  = " — ".join(filter(None, [veg_tag, cal, hs]))
            item_lines.append(
                f"{i}. {it['item_name']} @ {rest} — ₹{it['price']} — {extras}"
            )
        context = "\n".join(item_lines)

        loc = area_name or "your area"

        # Build soft preference hints
        hint_lines = []
        if soft_hints.get("section_name"):
            hint_lines.append(f"Prefer {soft_hints['section_name']} items.")
        if soft_hints.get("min_health_score"):
            hint_lines.append(f"Prefer health score >= {soft_hints['min_health_score']}/10.")
        if soft_hints.get("max_calories"):
            hint_lines.append(f"Prefer items <= {soft_hints['max_calories']} kcal.")
        pref_block = ("\nUser preferences: " + " ".join(hint_lines)) if hint_lines else ""

        user_prompt = (
            f'Someone near {loc} asked via voice: "{query}"\n\n'
            f"Available menu items:\n{context}"
            f"{pref_block}\n\n"
            "Write a warm, spoken-aloud recommendation in exactly 1-2 short sentences. "
            "Mention the best 1-2 items with restaurant name and price. "
            "No bullet points. No markdown. Sound natural."
        )

        # Build message list: [system] + [history…] + [user]
        messages = [{"role": "system", "content": _VOICE_SYSTEM_MSG}]
        messages.extend(history)
        messages.append({"role": "user", "content": user_prompt})

        try:
            client = self._get_groq_client()
            if client is None:
                return self._fallback_answer(query, items, loc)

            response = client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=messages,
                max_completion_tokens=100,      # short — voice needs brevity
                temperature=0.70,
            )
            answer = response.choices[0].message.content.strip()

            # Safety guard: if LLM returned something too long, truncate gracefully
            if len(answer) > 400:
                sentences = answer.split(". ")
                answer = ". ".join(sentences[:3]).strip()
                if not answer.endswith("."):
                    answer += "."

            return answer

        except Exception as e:
            logger.warning(f"VoiceRAG LLM call failed: {e}. Using fallback.")
            return self._fallback_answer(query, items, loc)

    def _fallback_answer(self, query: str, items: List[Dict[str, Any]], loc: str) -> str:
        """Rule-based fallback when the LLM is unavailable."""
        top = items[:2]
        parts = [
            f"{it['item_name']} at {it.get('restaurant_name', 'a nearby restaurant')} for ₹{it['price']}"
            for it in top
        ]
        if len(parts) == 1:
            return (
                f"I found a great match near {loc}: {parts[0]}. "
                "Would you like to add it to your cart?"
            )
        return (
            f"Near {loc}, you might enjoy {parts[0]}, or try {parts[1]}. "
            "Both look like great options for what you're looking for!"
        )

    # ── Groq client ────────────────────────────────────────────────────────────

    def _get_groq_client(self):
        if hasattr(self, "_groq_client") and self._groq_client is not None:
            return self._groq_client
        groq_key = getattr(settings, "GROQ_API_KEY", None)
        if not groq_key:
            logger.warning("VoiceRAG: GROQ_API_KEY not set — using fallback answers.")
            return None
        try:
            from groq import Groq
            self._groq_client = Groq(api_key=groq_key)
            return self._groq_client
        except ImportError:
            logger.warning("VoiceRAG: groq SDK not installed.")
            return None


# ── Singleton ─────────────────────────────────────────────────────────────────

_voice_rag: Optional[VoiceRAGService] = None


def get_voice_rag_service() -> VoiceRAGService:
    """Return the shared VoiceRAGService instance (one per process)."""
    global _voice_rag
    if _voice_rag is None:
        _voice_rag = VoiceRAGService()
    return _voice_rag
