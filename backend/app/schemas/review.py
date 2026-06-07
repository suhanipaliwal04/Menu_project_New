from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import uuid

class RestaurantReviewCreate(BaseModel):
    restaurant_id: uuid.UUID
    rating: float
    review_text: Optional[str] = None
    customer_name: Optional[str] = None

class RestaurantReviewResponse(BaseModel):
    review_id: uuid.UUID
    restaurant_id: uuid.UUID
    rating: float
    review_text: Optional[str] = None
    customer_name: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class AppReviewCreate(BaseModel):
    rating: float
    review_text: Optional[str] = None
    customer_name: Optional[str] = None

class AppReviewResponse(BaseModel):
    review_id: uuid.UUID
    rating: float
    review_text: Optional[str] = None
    customer_name: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
