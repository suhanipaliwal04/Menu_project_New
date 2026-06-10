"""
POST /api/v1/chat  — RAG-powered food discovery chatbot endpoint
"""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Depends
import math
from sqlalchemy.orm import Session

from app.services.nlp.rag_service import get_rag_service
from app.schemas.chat import ChatRequest, ChatResponse
from app.core.database import get_db
from app.models.restaurant import Restaurant

router = APIRouter()


# ── Endpoint ──────────────────────────────────────────────────────────────────

@router.post("", response_model=ChatResponse, summary="Ask the food discovery chatbot")
async def chat(req: ChatRequest, db: Session = Depends(get_db)):
    """
    Natural language food query → relevant menu items + conversational answer.
    """
    if not req.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty.")

    rag = get_rag_service()

    rest_id = req.restaurant_id if req.restaurant_id and req.restaurant_id != "string" else None
    
    restaurant_ids = None
    
    # If a specific location is given via Lat/Lng, find nearby restaurants.
    if req.user_lat is not None and req.user_lng is not None:
        all_restaurants = db.query(Restaurant).filter(
            Restaurant.is_active == True,
            Restaurant.is_open_manually.is_not(False)
        ).all()
        
        nearby_ids = []
        for r in all_restaurants:
            if r.latitude is not None and r.longitude is not None:
                R = 6371.0
                lat1 = math.radians(req.user_lat)
                lon1 = math.radians(req.user_lng)
                lat2 = math.radians(r.latitude)
                lon2 = math.radians(r.longitude)
                
                dlon = lon2 - lon1
                dlat = lat2 - lat1
                
                a = math.sin(dlat / 2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2)**2
                c = 2 * math.asin(math.sqrt(a))
                distance = R * c
                
                if distance <= 2.0:
                    nearby_ids.append(str(r.restaurant_id))
        
        restaurant_ids = nearby_ids
        # Even if area_name is provided, Lat/Lng takes precedence and sets the bounds.
        area_name = ""
    else:
        area_name = req.area_name or ""

    result = rag.chat(
        query=req.query,
        area_name=area_name,
        restaurant_id=rest_id,
        restaurant_ids=restaurant_ids,
        is_fast=req.is_fast
    )

    return ChatResponse(**result)
