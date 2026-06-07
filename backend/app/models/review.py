"""
Review Models
"""
from sqlalchemy import Column, String, DateTime, Float, ForeignKey, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from app.core.database import Base


class RestaurantReview(Base):
    __tablename__ = "restaurant_reviews"

    review_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    restaurant_id = Column(UUID(as_uuid=True), ForeignKey("restaurants.restaurant_id", ondelete="CASCADE"), nullable=False)
    rating = Column(Float, nullable=False)
    review_text = Column(Text, nullable=True)
    customer_name = Column(String(100), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    restaurant = relationship("Restaurant")

    def __repr__(self):
        return f"<RestaurantReview(id='{self.review_id}', rating='{self.rating}')>"


class AppReview(Base):
    __tablename__ = "app_reviews"

    review_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    rating = Column(Float, nullable=False)
    review_text = Column(Text, nullable=True)
    customer_name = Column(String(100), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    def __repr__(self):
        return f"<AppReview(id='{self.review_id}', rating='{self.rating}')>"
