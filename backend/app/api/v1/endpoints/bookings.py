from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import uuid
from datetime import datetime

from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.booking import Booking
from app.models.restaurant import Restaurant
from app.schemas.booking import BookingCreate, BookingUpdate, BookingResponse

from pydantic import BaseModel

class CustomerBookingsRequest(BaseModel):
    booking_ids: List[str]

router = APIRouter()

@router.post("/", response_model=BookingResponse)
def create_booking(
    booking: BookingCreate,
    db: Session = Depends(get_db)
):
    """
    Public endpoint for consumers to request a table booking.
    """
    # Verify restaurant exists and has dine-in
    restaurant = db.query(Restaurant).filter(Restaurant.restaurant_id == booking.restaurant_id).first()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
        
    if not getattr(restaurant, "has_dine_in", True):
        raise HTTPException(status_code=400, detail="This restaurant does not offer Dine-In")
        
    db_booking = Booking(
        restaurant_id=booking.restaurant_id,
        party_size=booking.party_size,
        time_slot=booking.time_slot,
        booking_date=booking.booking_date,
        customer_name=booking.customer_name,
        customer_phone=booking.customer_phone,
        status="PENDING"
    )
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)
    return db_booking

@router.get("/admin/restaurants/{restaurant_id}/bookings", response_model=List[BookingResponse])
def get_restaurant_bookings(
    restaurant_id: uuid.UUID,
    status_filter: str = None,
    current_user: uuid.UUID = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get all bookings for a specific restaurant. Only the owner can access this.
    """
    restaurant = db.query(Restaurant).filter(Restaurant.restaurant_id == restaurant_id).first()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
        
    if restaurant.owner_id != current_user:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
        
    query = db.query(Booking).filter(Booking.restaurant_id == restaurant_id)
    if status_filter:
        query = query.filter(Booking.status == status_filter)
        
    bookings = query.order_by(Booking.created_at.desc()).all()
    results = []
    for b in bookings:
        b_dict = {
            "booking_id": b.booking_id,
            "restaurant_id": b.restaurant_id,
            "restaurant_name": b.restaurant.restaurant_name if b.restaurant else None,
            "party_size": b.party_size,
            "time_slot": b.time_slot,
            "booking_date": b.booking_date,
            "customer_name": b.customer_name,
            "customer_phone": b.customer_phone,
            "status": b.status,
            "created_at": b.created_at,
            "updated_at": b.updated_at,
        }
        results.append(b_dict)
    return results

@router.put("/admin/bookings/{booking_id}", response_model=BookingResponse)
def update_booking_status(
    booking_id: uuid.UUID,
    update_data: BookingUpdate,
    current_user: uuid.UUID = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update a booking status (e.g., CONFIRMED, REJECTED). Only the restaurant owner can do this.
    """
    booking = db.query(Booking).filter(Booking.booking_id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    restaurant = db.query(Restaurant).filter(Restaurant.restaurant_id == booking.restaurant_id).first()
    if not restaurant or restaurant.owner_id != current_user:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
        
    if update_data.status not in ["PENDING", "CONFIRMED", "REJECTED", "CANCELLED"]:
        raise HTTPException(status_code=400, detail="Invalid status")
        
    booking.status = update_data.status
    db.commit()
    db.refresh(booking)
    return booking

@router.post("/customer", response_model=List[BookingResponse])
def get_customer_bookings(
    request: CustomerBookingsRequest,
    db: Session = Depends(get_db)
):
    """
    Get booking details for a list of booking IDs stored locally by the customer.
    """
    valid_uuids = []
    for bid in request.booking_ids:
        try:
            valid_uuids.append(uuid.UUID(bid))
        except ValueError:
            pass
            
    if not valid_uuids:
        return []
        
    bookings = db.query(Booking).filter(Booking.booking_id.in_(valid_uuids)).order_by(Booking.created_at.desc()).all()
    results = []
    for b in bookings:
        b_dict = {
            "booking_id": b.booking_id,
            "restaurant_id": b.restaurant_id,
            "restaurant_name": b.restaurant.restaurant_name if b.restaurant else None,
            "party_size": b.party_size,
            "time_slot": b.time_slot,
            "booking_date": b.booking_date,
            "customer_name": b.customer_name,
            "customer_phone": b.customer_phone,
            "status": b.status,
            "created_at": b.created_at,
            "updated_at": b.updated_at,
        }
        results.append(b_dict)
    return results

@router.delete("/admin/restaurants/{restaurant_id}/bookings", response_model=dict)
def clear_restaurant_bookings(
    restaurant_id: uuid.UUID,
    current_user: uuid.UUID = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Clear all bookings for a specific restaurant. Only the owner can do this.
    """
    restaurant = db.query(Restaurant).filter(Restaurant.restaurant_id == restaurant_id).first()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")
        
    if restaurant.owner_id != current_user:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
        
    db.query(Booking).filter(Booking.restaurant_id == restaurant_id).delete(synchronize_session=False)
    db.commit()
    
    return {"detail": "All bookings cleared successfully"}
