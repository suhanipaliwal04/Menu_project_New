"""
Pydantic schemas for the Admin Dashboard endpoints.
"""
import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class DashboardStats(BaseModel):
    """Dashboard overview for a single restaurant."""
    restaurant_id: uuid.UUID
    restaurant_name: str
    area_name: str
    city: str
    is_active: bool
    total_sections: int
    total_items: int
    total_uploads: int
    avg_price: Optional[float] = None
    veg_items: int
    non_veg_items: int
    total_bookings: int = 0
    pending_bookings: int = 0
    created_at: Optional[datetime] = None


class MenuItemSummary(BaseModel):
    """A single menu item row for the admin items table."""
    item_id: uuid.UUID
    item_name: str
    section_name: str
    price: float
    is_veg: bool
    is_available: bool
    description: Optional[str] = None
    calories: Optional[int] = None
    health_score: Optional[int] = None
    health_label: Optional[str] = None
    tags: Optional[List[str]] = None

    class Config:
        from_attributes = True


class MenuItemUpdate(BaseModel):
    """Schema for PUT /admin/restaurants/{id}/items/{item_id} — partial update."""
    item_name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    is_veg: Optional[bool] = None
    is_available: Optional[bool] = None
    calories: Optional[int] = None
    spice_level: Optional[str] = None
    tags: Optional[List[str]] = None


class MenuSectionSummary(BaseModel):
    """Lightweight section record for dropdowns in the admin UI."""
    section_id: uuid.UUID
    section_name: str
    item_count: int = 0

    class Config:
        from_attributes = True


class MenuItemCreate(BaseModel):
    """Schema for POST /admin/restaurants/{id}/items — manually add one item."""
    item_name: str = Field(..., min_length=1, max_length=255)
    section_name: str = Field(..., min_length=1, max_length=255)
    price: float = Field(..., ge=0)
    is_veg: bool = True
    description: Optional[str] = None
    calories: Optional[int] = None
    tags: Optional[List[str]] = None
