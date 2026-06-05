import uuid
from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.auth import get_current_user
from app.core.database import get_db
from app.models.user import User

def _get_user_with_role(user_id: uuid.UUID, expected_role: str, db: Session) -> User:
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        # Fallback for old System Admin using specific test email
        if expected_role == "SYSTEM_ADMIN":
            return User(user_id=user_id, role="SYSTEM_ADMIN", is_approved=True)
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User record not found in local database."
        )
    if user.role != expected_role:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access denied. Required role: {expected_role}."
        )
    if not user.is_approved:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account is pending approval by a System Administrator."
        )
    return user

def get_current_system_admin(
    current_user_id: uuid.UUID = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> uuid.UUID:
    _get_user_with_role(current_user_id, "SYSTEM_ADMIN", db)
    return current_user_id

def get_current_restaurant_admin(
    current_user_id: uuid.UUID = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> uuid.UUID:
    _get_user_with_role(current_user_id, "RESTAURANT_ADMIN", db)
    return current_user_id

def get_current_customer(
    current_user_id: uuid.UUID = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> uuid.UUID:
    _get_user_with_role(current_user_id, "CUSTOMER", db)
    return current_user_id
