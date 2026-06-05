"""
User Model
Tracks local user roles and approval status, synced with Supabase auth.users.
"""
from sqlalchemy import Column, String, DateTime, Boolean, func
from sqlalchemy.dialects.postgresql import UUID

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    # We use the same UUID as Supabase auth.users
    user_id = Column(UUID(as_uuid=True), primary_key=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    role = Column(String(50), nullable=False)  # 'SYSTEM_ADMIN', 'RESTAURANT_ADMIN', 'CUSTOMER'
    is_approved = Column(Boolean, default=False, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    def __repr__(self):
        return f"<User(email='{self.email}', role='{self.role}', approved={self.is_approved})>"
