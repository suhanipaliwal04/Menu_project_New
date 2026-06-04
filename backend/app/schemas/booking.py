import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel

class BookingBase(BaseModel):
    party_size: int
    time_slot: str

class BookingCreate(BookingBase):
    restaurant_id: uuid.UUID

class BookingUpdate(BaseModel):
    status: str  # PENDING, CONFIRMED, REJECTED, CANCELLED

class BookingResponse(BookingBase):
    booking_id: uuid.UUID
    restaurant_id: uuid.UUID
    status: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
