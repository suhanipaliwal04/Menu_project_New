import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel

class OrderItemBase(BaseModel):
    item_id: Optional[uuid.UUID] = None
    item_name: str
    quantity: int = 1
    price: float

class OrderItemResponse(OrderItemBase):
    order_item_id: uuid.UUID
    order_id: uuid.UUID

    class Config:
        from_attributes = True

class OrderBase(BaseModel):
    customer_name: str
    customer_phone: str
    time_slot: str
    total_amount: float

class OrderCreate(OrderBase):
    restaurant_id: uuid.UUID
    items: List[OrderItemBase]

class OrderUpdate(BaseModel):
    status: str

class OrderResponse(OrderBase):
    order_id: uuid.UUID
    restaurant_id: uuid.UUID
    status: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    items: List[OrderItemResponse] = []

    class Config:
        from_attributes = True
