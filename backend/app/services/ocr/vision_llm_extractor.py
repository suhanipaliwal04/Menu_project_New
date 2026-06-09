"""
Vision LLM Extractor - Map menu images directly to structured JSON using Gemini 2.5 Pro Vision.
"""

import os
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
        self.api_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={self.api_key}"

    def _encode_image(self, image_path: str) -> str:
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')

    def extract_menu(self, image_path: str, restaurant_name: str) -> List[Dict[str, Any]]:
        """
        Extract menu items directly from an image using Gemini Pro.
        Returns a list of structured items ready for DB insertion.
        """
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY is not set in environment variables.")

        img_path = Path(image_path)
        if not img_path.exists():
            raise FileNotFoundError(f"Image not found at {image_path}")

        try:
            logger.info("Extracting menu using Gemini Vision LLM...")
            
            base64_image = self._encode_image(image_path)
            
            prompt = f"""You are a strict data extractor for a restaurant menu digitizer.
Below is an image of a menu for the restaurant '{restaurant_name}'.

Your task is to carefully read the entire image, section by section, column by column, and extract EVERY SINGLE food or drink item.
DO NOT summarize. DO NOT skip any items. The menu may contain 50+ items, you must extract all of them.

Return ONLY a valid JSON array of objects. Do not include markdown blocks (like ```json). For EACH item return exactly this format:
[
  {{
    "item_name": "clean item name",
    "price": <number>,
    "section_name": "Category name",
    "is_veg": true or false,
    "calories": 200,
    "health_score": <integer 1-10>,
    "description": ""
  }}
]

CRITICAL RULES:
1. Extract ALL items found in the image. Go through every heading.
2. Prices MUST be numbers (e.g. 150). If an item has multiple prices (e.g., "20/30"), just extract the LOWEST base price.
3. Do not mistake UI elements (like battery percentage 77) as menu items. Only extract real menu content.
4. Return ONLY the raw JSON array.
5. "health_score" MUST be an integer between 1 and 10 (10 = healthiest). Use your best judgment based on ingredients (e.g. salads = 8-10, fried food/desserts = 1-4).
"""

            payload = {
                "contents": [
                    {
                        "parts": [
                            {"text": prompt},
                            {
                                "inlineData": {
                                    "mimeType": "image/jpeg",
                                    "data": base64_image
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

            headers = {"Content-Type": "application/json"}

            response = requests.post(self.api_url, headers=headers, json=payload, timeout=60)
            
            if response.status_code != 200:
                logger.error(f"Gemini API failed: {response.text}")
                raise RuntimeError(f"Gemini API error: {response.status_code} {response.text}")

            result_json = response.json()
            
            # Handle unexpected or empty responses safely
            if "candidates" not in result_json or not result_json["candidates"]:
                raise RuntimeError("Gemini API returned an empty response.")
                
            content_parts = result_json['candidates'][0].get('content', {}).get('parts', [])
            if not content_parts or 'text' not in content_parts[0]:
                raise RuntimeError("Gemini API failed to extract text from the image.")
                
            text_response = content_parts[0]['text']

            if not text_response:
                raise RuntimeError("Vision API returned empty content.")

            text_response = text_response.strip()
            if text_response.startswith("```json"):
                text_response = text_response[7:]
            if text_response.startswith("```"):
                text_response = text_response[3:]
            if text_response.endswith("```"):
                text_response = text_response[:-3]
                
            parsed_items = json.loads(text_response.strip())
            
            for item in parsed_items:
                try:
                    item["price"] = float(item.get("price", 0))
                except (ValueError, TypeError):
                    item["price"] = 0.0
                    
            logger.info(f"Successfully extracted {len(parsed_items)} items via Gemini Vision.")
            return parsed_items
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to call Vision API: {e}")
            raise RuntimeError(f"Vision API request failed: {e}")
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON from Vision API: {e}")
            raise ValueError("Vision API returned invalid JSON.")
        except Exception as e:
            logger.error(f"Failed extraction: {e}")
            raise

# Singleton
_extractor = None

def get_vision_extractor() -> VisionLLMExtractor:
    global _extractor
    if _extractor is None:
        _extractor = VisionLLMExtractor()
    return _extractor
