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

@router.get("/restaurants")
def get_all_restaurants(
    current_admin: uuid.UUID = Depends(get_current_system_admin),
    db: Session = Depends(get_db)
):
    """
    Returns a list of all restaurants in the system, bypassing the
    public filters (like is_active and time-of-day checks).
    """
    from app.models.restaurant import Restaurant
    from app.models.area import Area
    from app.schemas.restaurant import RestaurantResponse

    # Fetch all restaurants and join Area to populate the Pydantic schema
    restaurants = db.query(Restaurant).all()
    
    # We can just return the ORM models, FastAPI will serialize to dict if we don't specify response_model
    # but let's format it as expected by the frontend
    result = []
    for r in restaurants:
        result.append({
            "restaurant_id": r.restaurant_id,
            "owner_id": r.owner_id,
            "restaurant_name": r.restaurant_name,
            "area_id": r.area_id,
            "area_name": r.area.area_name if r.area else None,
            "city": r.area.city if r.area else None,
            "address": r.address,
            "phone_number": r.phone,
            "cuisine_type": r.cuisine_type,
            "price_category": r.price_category,
            "has_dine_in": r.has_dine_in,
            "has_takeaway": r.has_takeaway,
            "is_active": r.is_active,
            "is_open_manually": r.is_open_manually,
            "opening_time": r.opening_time.isoformat() if r.opening_time else None,
            "closing_time": r.closing_time.isoformat() if r.closing_time else None,
            "latitude": r.latitude,
            "longitude": r.longitude,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        })
    return result


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

@router.delete("/restaurants/{restaurant_id}")
def delete_restaurant(
    restaurant_id: uuid.UUID,
    current_admin: uuid.UUID = Depends(get_current_system_admin),
    db: Session = Depends(get_db)
):
    """
    Completely deletes a restaurant from the system.
    Due to ON DELETE CASCADE on the database relationships, this will also completely 
    delete all associated menu sections, menu items, and vector embeddings.
    The Restaurant Admin user account is left intact.
    """
    from app.models.restaurant import Restaurant

    restaurant = db.query(Restaurant).filter(Restaurant.restaurant_id == restaurant_id).first()
    
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found.")

    restaurant_name = restaurant.restaurant_name
    db.delete(restaurant)
    db.commit()

    return {"message": f"Restaurant '{restaurant_name}' and all its menu items were completely deleted."}

