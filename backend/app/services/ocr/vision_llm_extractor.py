"""
Vision LLM Extractor - Map menu images directly to structured JSON using Gemini Pro.
"""

import base64
import json
import logging
import requests
from typing import Dict, List, Any
from pathlib import Path

from app.core.config import settings

logger = logging.getLogger(__name__)

class VisionLLMExtractor:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        if not self.api_key:
            logger.warning("GEMINI_API_KEY is not configured.")

    def extract_menu(self, image_path: str, restaurant_name: str) -> List[Dict[str, Any]]:
        """
        Extract menu items directly from an image using Gemini Pro.
        Returns a list of structured items ready for DB insertion.
        """
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY is not set in environment variables.")

        # Read and encode the image
        img_path = Path(image_path)
        if not img_path.exists():
            raise FileNotFoundError(f"Image not found at {image_path}")

        with open(img_path, "rb") as f:
            encoded_image = base64.b64encode(f.read()).decode("utf-8")
        
        mime_type = "image/jpeg"
        if img_path.suffix.lower() == ".png":
            mime_type = "image/png"
        elif img_path.suffix.lower() == ".pdf":
            mime_type = "application/pdf"

        prompt = f"""You are a strict food classification system and data extractor.
Below is an image of a menu for the restaurant "{restaurant_name}".

Extract all menu items from this image and return a JSON array.
For EACH item return an object with the following fields:
[
  {{
    "item_name": "clean item name",
    "price": <number>,
    "section_name": "Category name (e.g., Starters, Main Course, Breads, Beverages, Desserts)",
    "is_veg": true or false (false for meat/egg/fish),
    "calories": <integer estimate, typically 100-600>,
    "health_score": <integer 1-10 (10 = healthiest)>,
    "description": "one short line description based on the item"
  }}
]

Rules:
1. Extract ALL items found in the image.
2. Prices MUST be numbers (e.g. 150, not "150").
3. Return ONLY a valid JSON array. Do not include markdown code blocks (```json) or any other text.
"""

        # Using Gemini 1.5 Pro
        url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key={self.api_key}"
        
        payload = {
            "contents": [
                {
                    "parts": [
                        {"text": prompt},
                        {
                            "inlineData": {
                                "mimeType": mime_type,
                                "data": encoded_image
                            }
                        }
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.1,
                "responseMimeType": "application/json"
            }
        }

        try:
            response = requests.post(url, json=payload, timeout=60)
            response.raise_for_status()
            
            data = response.json()
            if "candidates" not in data or not data["candidates"]:
                raise ValueError("No response from Gemini API.")
                
            text_response = data["candidates"][0]["content"]["parts"][0]["text"]
            
            # Clean up the response in case it contains markdown
            text_response = text_response.strip()
            if text_response.startswith("```json"):
                text_response = text_response[7:]
            if text_response.startswith("```"):
                text_response = text_response[3:]
            if text_response.endswith("```"):
                text_response = text_response[:-3]
                
            parsed_items = json.loads(text_response.strip())
            
            # Ensure price is float
            for item in parsed_items:
                try:
                    item["price"] = float(item.get("price", 0))
                except (ValueError, TypeError):
                    item["price"] = 0.0
                    
            return parsed_items
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to call Gemini API: {e}")
            raise RuntimeError(f"Vision API request failed: {e}")
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON from Gemini: {e}")
            raise ValueError("Vision API returned invalid JSON.")

# Singleton
_extractor = None

def get_vision_extractor() -> VisionLLMExtractor:
    global _extractor
    if _extractor is None:
        _extractor = VisionLLMExtractor()
    return _extractor
