"""
Location Models - Functional States and Cities where the system is active
"""
from sqlalchemy import Column, String, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid

from app.core.database import Base


class LocationState(Base):
    __tablename__ = "location_states"

    state_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    state_name = Column(String(100), unique=True, nullable=False, index=True)

    # Relationships
    cities = relationship("LocationCity", back_populates="state", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<LocationState(state_name='{self.state_name}')>"


class LocationCity(Base):
    __tablename__ = "location_cities"

    city_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    city_name = Column(String(100), nullable=False, index=True)
    state_id = Column(UUID(as_uuid=True), ForeignKey("location_states.state_id", ondelete="CASCADE"), nullable=False)

    # Relationships
    state = relationship("LocationState", back_populates="cities")

    def __repr__(self):
        return f"<LocationCity(city_name='{self.city_name}')>"
