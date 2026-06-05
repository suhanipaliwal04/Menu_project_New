"""
System Admin Endpoints
Handles global approval of restaurants, etc.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import uuid

from app.core.database import get_db
from app.core.auth_roles import get_current_system_admin
from app.models.user import User

router = APIRouter()

@router.get("/pending-restaurants")
def get_pending_restaurants(
    current_admin: uuid.UUID = Depends(get_current_system_admin),
    db: Session = Depends(get_db)
):
    """
    Returns a list of all Restaurant Admins whose accounts are pending approval.
    """
    pending_users = db.query(User).filter(
        User.role == "RESTAURANT_ADMIN",
        User.is_approved == False
    ).all()

    return [
        {
            "user_id": user.user_id,
            "email": user.email,
            "created_at": user.created_at
        }
        for user in pending_users
    ]

@router.post("/approve-restaurant/{user_id}")
def approve_restaurant(
    user_id: uuid.UUID,
    current_admin: uuid.UUID = Depends(get_current_system_admin),
    db: Session = Depends(get_db)
):
    """
    Approves a pending Restaurant Admin so they can log in.
    """
    user = db.query(User).filter(
        User.user_id == user_id,
        User.role == "RESTAURANT_ADMIN"
    ).first()

    if not user:
        raise HTTPException(status_code=404, detail="Restaurant admin not found.")

    if user.is_approved:
        return {"message": "Restaurant admin is already approved."}

    user.is_approved = True
    db.commit()

    return {"message": f"Restaurant admin {user.email} approved successfully."}
