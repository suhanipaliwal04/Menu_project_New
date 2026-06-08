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
        
        try:
            logger.info(f"Extracting menu using OpenRouter Vision ({self.model})...")
            
            # Encode image to base64
            base64_image = self._encode_image(image_path)
            
            # Construct the prompt
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
    "health_score": 5,
    "description": ""
  }}
]

CRITICAL RULES:
1. Extract ALL items found in the image. Go through every heading.
2. Prices MUST be numbers (e.g. 150). If an item has multiple prices (e.g., "20/30"), just extract the LOWEST base price.
3. Do not mistake UI elements (like battery percentage 77) as menu items. Only extract real menu content.
4. Return ONLY the raw JSON array.
"""

            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "HTTP-Referer": "http://localhost:8000",
                "X-Title": "Menu Digitizer",
                "Content-Type": "application/json"
            }

            payload = {
                "model": self.model,
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
                        ]
                    }
                ],
                "temperature": 0.1
            }

            response = requests.post(self.api_url, headers=headers, json=payload, timeout=60)
            
            if response.status_code != 200:
                logger.error(f"OpenRouter API failed: {response.text}")
                raise RuntimeError(f"OpenRouter API error: {response.status_code} {response.text}")

            result_json = response.json()
            text_response = result_json['choices'][0]['message']['content']

            # Clean markdown formatting if model still adds it
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
