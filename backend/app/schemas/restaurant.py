"""
Pydantic schemas for Restaurant entities.
"""
import uuid
from datetime import datetime, time
from typing import List, Optional
from pydantic import BaseModel


class RestaurantBase(BaseModel):
    """Shared fields for all restaurant schemas."""
    restaurant_name: str
    cuisine_type: Optional[List[str]] = None
    price_category: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None


class RestaurantCreate(RestaurantBase):
    """Schema for POST /restaurants — creating a new restaurant."""
    area_id: uuid.UUID


class RestaurantUpdate(BaseModel):
    """Schema for PUT /restaurants/{id} — partial update (all fields optional)."""
    restaurant_name: Optional[str] = None
    area_id: Optional[uuid.UUID] = None
    cuisine_type: Optional[List[str]] = None
    price_category: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    is_active: Optional[bool] = None
    has_dine_in: Optional[bool] = None
    has_takeaway: Optional[bool] = None
    is_open_manually: Optional[bool] = None
    opening_time: Optional[time] = None
    closing_time: Optional[time] = None
    slot_duration_mins: Optional[int] = None
    max_dine_in_per_slot: Optional[int] = None


class RestaurantResponse(RestaurantBase):
    """Schema for GET /restaurants — reading restaurant data."""
    restaurant_id: uuid.UUID
    area_id: uuid.UUID
    owner_id: Optional[uuid.UUID] = None
    is_active: bool
    area_name: Optional[str] = None
    city: Optional[str] = None
    has_dine_in: bool = True
    has_takeaway: bool = True
    is_open_manually: bool = True
    opening_time: Optional[time] = None
    closing_time: Optional[time] = None
    slot_duration_mins: int = 15
    max_dine_in_per_slot: int = 5
    average_rating: float = 4.8
    total_reviews: int = 0
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
