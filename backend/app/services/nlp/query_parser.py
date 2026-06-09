"""
Query Parser — converts raw user text into structured search filters.

Two-stage approach:
  1. Rule-based pass (fast, no API call): regex + keyword matching
  2. LLM pass (Groq llama-3.1-8b-instant, ~200ms): fills in what rules miss for complex queries

Output schema:
  {
    "semantic_query":    str,
    "is_veg":           bool | None,
    "max_price":        int  | None,
    "min_price":        int  | None,
    "max_calories":     int  | None,
    "min_health_score": int  | None,
    "section_name":     str  | None,
    "exclude_keywords": list[str],
  }
"""

from __future__ import annotations

import json
import logging
import re
from typing import Dict, Any, Optional

from app.core.config import settings

logger = logging.getLogger(__name__)


# ── Category keyword map ───────────────────────────────────────────────────────
_SECTION_KEYWORDS: list[tuple[list[str], str]] = [
    (["chinese", "noodles", "manchurian", "momos"],       "Chinese"),
    (["north indian", "punjabi", "paneer", "dal makhani"], "North Indian"),
    (["south indian", "dosa", "idli"],                    "South Indian"),
    (["fast food", "pizza", "burger", "pasta", "fries"],  "Fast Food"),
    (["street food", "chaat", "pani puri", "pav bhaji"],  "Street Food"),
    (["biryani", "dum biryani", "pulao"],                 "Biryani"),
    (["rice", "fried rice", "jeera rice"],                "Rice & Noodles"),
    (["bread", "roti", "naan", "paratha", "kulcha"],      "Indian Breads"),
    (["curry", "gravy", "masala"],                        "Curries & Gravies"),
    (["starter", "snack", "appetizer", "tikka", "kebab"], "Snacks & Starters"),
    (["dessert", "sweet", "ice cream", "brownie", "cake"],"Desserts"),
    (["beverage", "drink", "juice", "shake", "coffee"],   "Beverages"),
    (["salad", "healthy", "soup"],                        "Salads & Healthy"),
    (["thali", "combo", "meal"],                          "Thali & Combos"),
    (["tandoor", "grill", "roast", "tikka"],              "Tandoor & Grills"),
    (["seafood", "fish", "prawn", "crab"],                "Seafood"),
    (["egg", "anda", "omelette"],                         "Egg Dishes"),
]

# ── Healthy / diet keywords ────────────────────────────────────────────────────
_HEALTHY_WORDS    = {"healthy", "healthy", "light", "low calorie", "diet",
                     "nutritious", "nutritious", "fit", "clean"}
_LOW_CAL_WORDS    = {"low calorie", "low-calorie", "fewer calories",
                     "less calories", "diet", "light"}
_VEG_WORDS        = {"veg", "vegetarian", "veggie", "vegan", "jain", "plant", "plant-based", "no meat",
                     "without meat"}
_NONVEG_WORDS     = {"non-veg", "nonveg", "chicken", "mutton", "fish",
                     "prawn", "seafood", "meat", "egg"}


def _rule_parse(query: str) -> Dict[str, Any]:
    """Fast, regex + keyword-based extraction. No API call."""
    q = query.lower().strip()
    result: Dict[str, Any] = {
        "semantic_query":    query,
        "is_veg":           None,
        "max_price":        None,
        "min_price":        None,
        "max_calories":     None,
        "min_health_score": None,
        "min_rating":       None,
        "section_name":     None,
        "exclude_keywords": [],
    }

    # ── Negative keywords (e.g. "other than rice", "without paneer") ──────────
    m_neg = re.findall(r'(?:without|no\s+|other\s+than|except|exclude|not)\s+([a-zA-Z]+)', q)
    if m_neg:
        result["exclude_keywords"].extend(m_neg)

    # ── Price filters ─────────────────────────────────────────────────────────
    # Handles: "under ₹200", "less than 300", "below 150", "upto 200", "cheap under 100", "budget of 500", "max 300", "200 bucks"
    m = re.search(r'(?:under|below|less\s+than|upto|up\s+to|within|<|max(?:imum)?|budget\s*(?:of)?)\s*(?:rs\.?|rupees|bucks|₹)?\s*(\d+)\s*(?:bucks|rupees|rs\.?)?(?!\s*(?:star|rating|review))', q)
    if m:
        result["max_price"] = int(m.group(1))

    m = re.search(r'(?:above|over|more\s+than|minimum|min|>)\s*(?:rs\.?|rupees|bucks|₹)?\s*(\d+)\s*(?:bucks|rupees|rs\.?)?(?!\s*(?:star|rating|review))', q)
    if m:
        result["min_price"] = int(m.group(1))

    # ── Review filters ────────────────────────────────────────────────────────
    m = re.search(r'(?:above|over|more\s+than|minimum|min|>|atleast|at\s+least)?\s*(\d+(?:\.\d+)?)\+?\s*(?:star|rating)', q)
    if m:
        result["min_rating"] = float(m.group(1))

    # ── Calorie filters ───────────────────────────────────────────────────────
    # Handles: "sub 400 calories", "max 500 kcal", "under 300 cal"
    m = re.search(r'(?:under|below|less\s+than|low[- ]?er\s+than|sub|max(?:imum)?)\s*(\d+)\s*(?:kcal|cal|calories)', q)
    if m:
        result["max_calories"] = int(m.group(1))

    if re.search(r'\b(?:' + '|'.join(map(re.escape, _LOW_CAL_WORDS)) + r')\b', q):
        result["max_calories"] = result["max_calories"] or 400

    # ── Health score ──────────────────────────────────────────────────────────
    if re.search(r'\b(?:' + '|'.join(map(re.escape, _HEALTHY_WORDS)) + r')\b', q):
        result["min_health_score"] = 6

    m = re.search(r'health\s*(?:score)?\s*(?:above|over|>=|>)\s*(\d+)', q)
    if m:
        result["min_health_score"] = int(m.group(1))

    # ── Veg / Non-veg ─────────────────────────────────────────────────────────
    if re.search(r'\b(?:' + '|'.join(map(re.escape, _NONVEG_WORDS)) + r')\b', q):
        result["is_veg"] = False
    elif re.search(r'\b(?:' + '|'.join(map(re.escape, _VEG_WORDS)) + r')\b', q):
        result["is_veg"] = True

    # ── Category / section ────────────────────────────────────────────────────
    for keywords, section in _SECTION_KEYWORDS:
        if re.search(r'\b(?:' + '|'.join(map(re.escape, keywords)) + r')\b', q):
            result["section_name"] = section
            break

    clean = re.sub(
        r'(under|below|less than|upto|up to|above|over|more than|minimum|within|max|maximum|budget of|sub)\s*(?:rs\.?|rupees|bucks|₹)?\s*\d+\s*(bucks|rupees|rs\.?|kcal|cal|calories)?(?!\s*(?:star|rating|review))',
        '', q, flags=re.IGNORECASE
    )
    clean = re.sub(r'\b(healthy|veg(etarian)?|non.?veg|cheap|affordable|expensive)\b',
                   '', clean, flags=re.IGNORECASE)
    clean = re.sub(r'(?:without|no\s+|other\s+than|except|exclude|not)\s+[a-zA-Z]+', '', clean, flags=re.IGNORECASE)
    clean = re.sub(r'\s{2,}', ' ', clean).strip()
    result["semantic_query"] = clean or query

    return result


def _llm_parse(query: str, rule_result: Dict[str, Any]) -> Dict[str, Any]:
    """
    Use Groq (llama-3.1-8b-instant) to fill in filters that rules missed.
    Only called when at least one key filter is still None.
    Returns merged result (LLM overrides None-valued rule fields only).
    Groq responds in ~200ms vs HuggingFace's ~5-8s.
    """
    groq_key = getattr(settings, "GROQ_API_KEY", None)
    if not groq_key:
        logger.debug("QueryParser: No GROQ_API_KEY, skipping LLM parse.")
        return rule_result

    try:
        from groq import Groq
    except ImportError:
        logger.warning("groq SDK not installed — skipping LLM parse.")
        return rule_result

    prompt = f"""You are a precise restaurant search query parser. Extract filters from the user's query.

Return ONLY a JSON object (no extra text):
{{
  "is_veg": true/false/null,
  "max_price": integer or null,
  "min_price": integer or null,
  "max_calories": integer or null,
  "min_health_score": integer 1-10 or null,
  "section_name": string or null,
  "semantic_query": "cleaned query"
}}

CRITICAL RULES:
1. is_veg: MUST be `null` UNLESS the user explicitly states a hard dietary filter like "veg", "vegetarian", "plant based" (true) OR "chicken", "mutton", "fish", "meat", "egg", "non veg" (false). Do NOT guess. Do NOT infer it from cuisine (e.g. "North Indian", "Burger" does NOT imply non-veg). Default is ALWAYS `null`.
2. max_price: The upper limit in rupees (e.g., "under 200", "below 500"). Must be `null` if not mentioned. If the user says "over 200", do NOT set max_price to 200.
3. min_price: The lower limit in rupees (e.g., "over 200", "above 500"). Must be `null` if not mentioned. If the user says "under 200", do NOT set min_price to 200.
4. min_health_score: 6 if "healthy", 7 if "very healthy". `null` otherwise.
5. min_rating: The lower limit for review ratings, e.g. 4.0 if "above 4 stars". `null` if not mentioned.
6. section_name: Match to a category like "North Indian", "Chinese", "Desserts", etc. `null` if not mentioned.
7. semantic_query: The remaining food intent with prices/dietary words removed.
8. CONFIDENCE: If you are not 100% sure about a filter, set it to `null`. It's better to have fewer hard filters than incorrect ones.

EXAMPLES:
Q: "something over 200 rs"
{{"is_veg": null, "max_price": null, "min_price": 200, "max_calories": null, "min_health_score": null, "section_name": null, "semantic_query": "something"}}

Q: "healthy veg food under 300"
{{"is_veg": true, "max_price": 300, "min_price": null, "max_calories": null, "min_health_score": 6, "section_name": null, "semantic_query": "food"}}

Q: "spicy chicken biryani"
{{"is_veg": false, "max_price": null, "min_price": null, "max_calories": null, "min_health_score": null, "section_name": "Biryani", "semantic_query": "spicy chicken biryani"}}

Q: "Something in North Indian"
{{"is_veg": null, "max_price": null, "min_price": null, "max_calories": null, "min_health_score": null, "section_name": "North Indian", "semantic_query": "Something in"}}

Q: "{query}"
"""

    try:
        client = Groq(api_key=groq_key)
        response = client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=300,
            temperature=0.1,
        )
        raw = response.choices[0].message.content.strip()
        raw = re.sub(r'^```(?:json)?\s*', '', raw, flags=re.MULTILINE)
        raw = re.sub(r'```\s*$',          '', raw, flags=re.MULTILINE)

        match = re.search(r'\{.*\}', raw, re.DOTALL)
        if not match:
            return rule_result

        llm_result = json.loads(match.group(0))

        # Merge: LLM overrides only where rule_result has None
        merged = dict(rule_result)
        for key in ("is_veg", "max_price", "min_price", "max_calories",
                    "min_health_score", "min_rating", "section_name", "semantic_query"):
            if merged.get(key) is None and llm_result.get(key) is not None:
                merged[key] = llm_result[key]

        return merged

    except Exception as e:
        logger.warning(f"QueryParser Groq LLM pass failed: {e}. Using rule-based result.")
        return rule_result


class QueryParser:
    """
    Parse a natural language query into structured search filters.
    Uses fast rules first, then optionally calls Groq llama-3.1-8b-instant (~200ms)
    for complex/colloquial queries that rule-based parsing misses.
    """

    def __init__(self, use_llm: bool = True):
        self.use_llm = use_llm and bool(getattr(settings, "GROQ_API_KEY", None))

    def parse(self, query: str) -> Dict[str, Any]:
        """
        Returns a filter dict:
          semantic_query, is_veg, max_price, min_price,
          max_calories, min_health_score, section_name
        """
        result = _rule_parse(query)

        # Only call LLM if at least most filter keys are still None
        # (avoids wasting an API call when rules already extracted everything)
        none_count = sum(1 for k in ("is_veg", "max_price", "section_name")
                         if result[k] is None)

        if self.use_llm and none_count >= 2:
            result = _llm_parse(query, result)

        logger.info(f"QueryParser: '{query}' → {result}")
        return result


# ── Singleton ─────────────────────────────────────────────────────────────────
_parser: Optional[QueryParser] = None

def get_query_parser() -> QueryParser:
    global _parser
    if _parser is None:
        _parser = QueryParser()
    return _parser
