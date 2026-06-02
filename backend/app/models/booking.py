"""
Booking Model
"""
from sqlalchemy import Column, String, DateTime, ForeignKey, Integer, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from app.core.database import Base


class Booking(Base):
    __tablename__ = "bookings"

    booking_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    restaurant_id = Column(UUID(as_uuid=True), ForeignKey("restaurants.restaurant_id", ondelete="CASCADE"), nullable=False)
    # If users are authenticated, you can link to user_id. For voice, we might just store phone/name or null.
    # user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    party_size = Column(Integer, nullable=False)
    time_slot = Column(String(50), nullable=False)
    status = Column(String(20), default="PENDING")  # PENDING, CONFIRMED, REJECTED, CANCELLED
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    restaurant = relationship("Restaurant")

    def __repr__(self):
        return f"<Booking(id='{self.booking_id}', status='{self.status}')>"
