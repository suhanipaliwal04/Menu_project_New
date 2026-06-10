"""
RAG Service — orchestrates the full Retrieval-Augmented Generation pipeline.

Flow:
  1. QueryParser  → extract filters + clean semantic query (rules + Groq fallback)
  2. EmbeddingService.hybrid_search(area_name=...) → items from ALL restaurants in the area
  3. Groq llama-3.1-8b-instant → generate natural language response comparing across restaurants

Usage:
    svc = RAGService()
    result = svc.chat("non-veg curry under ₹200 near me", area_name="Nagpur")
    print(result["answer"])
    print(result["items"])
"""

from __future__ import annotations

import logging
from typing import Dict, Any, List, Optional

from app.core.config import settings
from app.services.nlp.query_parser import get_query_parser
from app.services.nlp.embedding_service import get_embedding_service

logger = logging.getLogger(__name__)


class RAGService:
    """
    End-to-end RAG pipeline for location-aware multi-restaurant food discovery.
    """

    def __init__(self, top_k: int = 10):
        self.top_k      = top_k
        self.parser     = get_query_parser()
        self._groq_client = None

    # ── Hard vs Soft filter split ──────────────────────────────────────────────
    HARD_FILTER_KEYS = {"is_veg", "max_price", "min_price", "min_rating", "max_calories", "min_health_score"}
    SOFT_FILTER_KEYS = {"section_name"}

    # ── Public API ─────────────────────────────────────────────────────────────

    def chat(self,
             query:         str,
             area_name:     str = "",
             restaurant_id: Optional[str] = None,
             restaurant_ids: Optional[List[str]] = None,
             is_fast:       bool = False) -> Dict[str, Any]:
        """
        Answer a natural language food query for a given area.
        Searches across ALL restaurants in the area unless restaurant_id is given.

        Returns:
            {
              "answer":       str,         # LLM-generated response
              "items":        List[dict],  # top retrieved menu items with restaurant_name
              "filters_used": dict,
            }
        """
        # 1. Parse query → structured filters
        filters = self.parser.parse(query)
        logger.info(f"RAG: parsed filters = {filters}")

        # 2. Pass filters to EmbeddingService (SQL where clauses + soft boosting)
        search_filters = {k: v for k, v in filters.items()
                          if k in self.HARD_FILTER_KEYS and v is not None}
        search_filters["semantic_query"] = filters.get("semantic_query", query)
        
        # Inject soft-boost properties and excude keywords
        if filters.get("section_name"):
            search_filters["section_name"] = filters["section_name"]
        if filters.get("exclude_keywords"):
            search_filters["exclude_keywords"] = filters["exclude_keywords"]

        final_restaurant_ids = restaurant_ids or ([restaurant_id] if restaurant_id else None)

        svc = get_embedding_service()
        items = svc.hybrid_search(
            query=query,
            filters=search_filters,
            top_k=self.top_k,
            restaurant_ids=final_restaurant_ids,
            area_name=area_name or None,
            is_fast=is_fast,
        )

        if not items:
            return {
                "answer":       "Sorry, I couldn't find any matching items near you. Try broadening your search!",
                "items":        [],
                "filters_used": filters,
            }

        # 3. LLM re-ranks and generates human response
        answer = self._generate_answer(query, items, area_name, filters=filters)

        return {
            "answer":       answer,
            "items":        items,
            "filters_used": filters,
        }

    # ── LLM Response Generation ────────────────────────────────────────────────

    def _generate_answer(self,
                         query:      str,
                         items:      List[Dict[str, Any]],
                         area_name:  str,
                         filters:    Optional[Dict[str, Any]] = None) -> str:
        """Groq selects 3-4 best items from candidates and writes a human response."""

        filters = filters or {}

        # Format items: "ItemName @ RestaurantName — Category — ₹Price — Veg — Cal — Health"
        item_lines = []
        for i, it in enumerate(items, 1):
            veg_tag = "Veg" if it.get("is_veg") else "Non-Veg"
            cal     = f"{it['calories']} kcal" if it.get("calories") else "?"
            hs      = f"health {it['health_score']}/10" if it.get("health_score") else ""
            rest    = it.get("restaurant_name", "Unknown Restaurant")
            item_lines.append(
                f"{i}. {it['item_name']} @ {rest} — {it.get('section_name','?')} — "
                f"₹{it['price']} — {veg_tag} — {cal} {hs}"
            )
        context = "\n".join(item_lines)

        loc = area_name or "your area"

        # Explicit constraints for the LLM
        hint_lines = []
        if filters.get("is_veg") is not None:
            diet = "Pure Veg" if filters["is_veg"] else "Non-Veg"
            hint_lines.append(f"- MUST be {diet} items")
        if filters.get("max_price") is not None:
            hint_lines.append(f"- MUST be strictly under ₹{filters['max_price']}")
        if filters.get("min_price") is not None:
            hint_lines.append(f"- MUST be strictly over ₹{filters['min_price']}")
        if filters.get("section_name"):
            hint_lines.append(f"- Prefer {filters['section_name']} items")
        if filters.get("min_health_score") is not None:
            hint_lines.append(f"- MUST have health score >= {filters['min_health_score']}/10")
        if filters.get("max_calories") is not None:
            hint_lines.append(f"- MUST be strictly <= {filters['max_calories']} kcal")
        if filters.get("min_rating") is not None:
            hint_lines.append(f"- MUST be from a restaurant with avg rating >= {filters['min_rating']} stars")
        if filters.get("exclude_keywords"):
            hint_lines.append(f"- MUST EXCLUDE items containing: {', '.join(filters['exclude_keywords'])}")

        pref_block = ("\nUser strict constraints & preferences:\n" + "\n".join(hint_lines)) if hint_lines else ""

        system_msg = (
            "You are an enthusiastic, local foodie and expert restaurant guide. "
            "You help people discover amazing food near them. Speak warmly, naturally, and with excitement, "
            "like a knowledgeable friend who knows all the hidden gems. Feel free to use a couple of relevant emojis. "
            "Never sound robotic or corporate. "
            "CRITICAL: Do NOT contradict the user's constraints in your response. "
            "For example, if the user asks for items OVER ₹200, do not say 'Here are dishes under 200'. "
            "Rely strictly on the provided 'User strict constraints & preferences' block."
        )

        prompt = f"""Someone near {loc} is looking for food and asked:
"{query}"

Here are menu items from nearby restaurants:
{context}
{pref_block}

Write a punchy, engaging 1-2 sentence recommendation:
- Pick the 1-2 BEST matching items that perfectly satisfy the user strict constraints.
- Clearly mention the item name, restaurant, and price.
- Be extremely brief and conversational. No long explanations.
- Use an emoji or two to make it pop!
- No bullet points, no numbering."""

        try:
            client = self._get_groq_client()
            if client is None:
                return self._fallback_answer(query, items)

            response = client.chat.completions.create(
                model="llama-3.1-8b-instant",  # Groq's fast llama3 model
                messages=[
                    {"role": "system", "content": system_msg},
                    {"role": "user",   "content": prompt},
                ],
                max_tokens=150,
                temperature=0.75,
            )
            return response.choices[0].message.content.strip()

        except Exception as e:
            logger.warning(f"RAG LLM response failed: {e}. Using fallback.")
            return self._fallback_answer(query, items)

    def _fallback_answer(self, query: str, items: List[Dict[str, Any]]) -> str:
        top3 = items[:3]
        parts = [
            f"{it['item_name']} at {it.get('restaurant_name','?')} (₹{it['price']})"
            for it in top3
        ]
        return (
            f"Here are some great matches for \"{query}\" near you: "
            + ", ".join(parts) + ". All options were selected based on your query."
        )

    def _get_groq_client(self):
        if self._groq_client is not None:
            return self._groq_client
        groq_key = getattr(settings, "GROQ_API_KEY", None)
        if not groq_key:
            return None
        try:
            from groq import Groq
            self._groq_client = Groq(api_key=groq_key)
            return self._groq_client
        except ImportError:
            logger.warning("groq SDK not installed.")
            return None


# ── Singleton ─────────────────────────────────────────────────────────────────
_rag_service: Optional[RAGService] = None

def get_rag_service() -> RAGService:
    global _rag_service
    if _rag_service is None:
        _rag_service = RAGService()
    return _rag_service


