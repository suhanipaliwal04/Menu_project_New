"""
Google Vision OCR — lightweight REST-based text extraction.

Used when OCR_ENGINE='google_vision' (Render deployment).
No local PaddleOCR/torch dependencies needed — just an HTTP call.
"""
import base64
import requests
import logging

logger = logging.getLogger(__name__)


def extract_text_google_vision(image_path: str, api_key: str) -> str:
    """
    Send an image to the Google Vision API (DOCUMENT_TEXT_DETECTION)
    and return the full extracted text as a single string.

    Args:
        image_path: Absolute path to the saved image file.
        api_key: Google Vision API key (from GOOGLE_VISION_API_KEY env var).

    Returns:
        Extracted text string (empty string on failure).
    """
    with open(image_path, "rb") as f:
        image_bytes = f.read()

    encoded = base64.b64encode(image_bytes).decode("utf-8")

    url = f"https://vision.googleapis.com/v1/images:annotate?key={api_key}"
    payload = {
        "requests": [
            {
                "image": {"content": encoded},
                "features": [
                    {"type": "DOCUMENT_TEXT_DETECTION", "maxResults": 1}
                ],
            }
        ]
    }

    try:
        resp = requests.post(url, json=payload, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        annotation = (
            data.get("responses", [{}])[0]
            .get("fullTextAnnotation", {})
            .get("text", "")
        )
        logger.info(
            f"[GoogleVision] Extracted {len(annotation)} characters"
        )
        return annotation
    except Exception as e:
        logger.error(f"[GoogleVision] OCR failed: {e}")
        return ""
