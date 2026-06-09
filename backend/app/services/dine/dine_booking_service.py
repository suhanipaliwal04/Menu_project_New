"""
Dine-In Booking Service
───────────────────────
Handles table availability checks and booking confirmations.

Uses mock availability data (easy to swap to real DB queries).
Each restaurant has time slots from 6:00 PM to 11:00 PM in 30-min intervals.
Each slot has a max_capacity (tables available for that slot).

Usage:
    svc = get_dine_booking_service()
    result = svc.check_availability(restaurant_id="abc", time_slot="7:00 PM", party_size=5)
    # result = {
    #   "available": False,
    #   "reason": "time_unavailable",         # or "seats_unavailable"
    #   "alternative_slots": ["7:30 PM", "8:00 PM", ...],
    #   "nearby_restaurants": [...],
    # }
"""

import uuid
import logging
from datetime import datetime
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models.booking import Booking
from app.models.restaurant import Restaurant
from datetime import timedelta

logger = logging.getLogger(__name__)

# ── Dynamic slot generation ──────────────────────────────────────────────────

def _get_restaurant_slots(restaurant_id: str, db: Session) -> List[str]:
    restaurant = db.query(Restaurant).filter(Restaurant.restaurant_id == restaurant_id).first()
    if not restaurant or not restaurant.opening_time or not restaurant.closing_time:
        return ["6:00 PM", "7:00 PM", "8:00 PM", "9:00 PM", "10:00 PM", "11:00 PM"]
    
    slot_duration = getattr(restaurant, "slot_duration_mins", 15)
    
    slots = []
    current = datetime.combine(datetime.today(), restaurant.opening_time)
    closing = datetime.combine(datetime.today(), restaurant.closing_time)
    
    if closing < current:
        closing += timedelta(days=1)
        
    while current <= closing:
        slots.append(current.strftime("%I:%M %p").lstrip('0'))
        current += timedelta(minutes=slot_duration)
        
    return slots

# ── Slot normalization ─────────────────────────────────────────────────────────

def _normalize_slot(slot: str, valid_slots: List[str]) -> Optional[str]:
    """
    Normalize user-provided time strings to our standard slot format.
    Handles: "7pm", "7:00pm", "7:00 PM", "7 pm", "19:00" etc.
    Returns None if not recognizable.
    """
    slot = slot.strip().upper()

    try:
        if ":" in slot and "M" not in slot:
            h, m = slot.split(":")
            h, m = int(h), int(m)
            if h >= 12:
                period = "PM"
                h = h if h == 12 else h - 12
            else:
                period = "AM"
            return f"{h}:{m:02d} {period}"
    except Exception:
        pass

    import re
    m = re.match(r"(\d{1,2})(?::(\d{2}))?\s*(AM|PM)", slot)
    if m:
        hour = int(m.group(1))
        minute = int(m.group(2) or "0")
        period = m.group(3)
        if minute < 15:
            minute = 0
        elif minute < 45:
            minute = 30
        else:
            minute = 0
            hour += 1
        candidate = f"{hour}:{minute:02d} {period}"
        if candidate in valid_slots:
            return candidate
        direct = f"{int(m.group(1))}:{int(m.group(2) or 0):02d} {m.group(3)}"
        if direct in valid_slots:
            return direct
    return None

def _find_slot(raw_time: str, valid_slots: List[str]) -> Optional[str]:
    normalized = _normalize_slot(raw_time, valid_slots)
    if normalized and normalized in valid_slots:
        return normalized
    raw_upper = raw_time.strip().upper()
    for s in valid_slots:
        if s.replace(" ", "") == raw_upper.replace(" ", ""):
            return s
    return None


class DineBookingService:

    def check_availability(
        self,
        restaurant_id: str,
        restaurant_name: str,
        time_slot: str,
        party_size: int,
    ) -> Dict[str, Any]:
        """
        Since capacity checks are removed and moved to the admin dashboard,
        we just validate the time slot and accept the booking request.
        """
        db: Session = SessionLocal()
        try:
            valid_slots = _get_restaurant_slots(restaurant_id, db)
            matched_slot = _find_slot(time_slot, valid_slots)
    
            if matched_slot is None:
                # Slot is out of operating hours or unrecognized
                logger.info(f"DineBooking: time '{time_slot}' not recognized.")
                return {
                    "available": False,
                    "confirmed_slot": None,
                    "reason": "time_unavailable",
                    "alternative_slots": valid_slots[:3] if valid_slots else ["7:00 PM", "8:00 PM", "9:00 PM"],
                    "nearby_restaurants": [],
                }
    
            date_str = datetime.utcnow().strftime("%d %b %Y")
            bookings = db.query(Booking).filter(
                Booking.restaurant_id == restaurant_id,
                Booking.booking_date == date_str,
                Booking.time_slot == matched_slot,
                Booking.status.in_(["PENDING", "CONFIRMED"])
            ).all()
            restaurant = db.query(Restaurant).filter(Restaurant.restaurant_id == restaurant_id).first()
            max_dine_in_per_slot = getattr(restaurant, "max_dine_in_per_slot", 5) if restaurant else 5
            max_capacity = getattr(restaurant, "max_capacity", 100) if restaurant else 100

            num_bookings = len(bookings)
            slot_people_count = sum(b.party_size for b in bookings)
            
            if num_bookings >= max_dine_in_per_slot or (slot_people_count + party_size) > max_capacity:
                logger.info(f"DineBooking: '{matched_slot}' full for {party_size} at '{restaurant_name}' (Bookings: {num_bookings}/{max_dine_in_per_slot}, Capacity: {slot_people_count + party_size}/{max_capacity})")
                return {
                    "available": False,
                    "confirmed_slot": None,
                    "reason": "time_unavailable",
                    "alternative_slots": [s for s in valid_slots if s != matched_slot][:3],
                    "nearby_restaurants": [],
                }
        finally:
            db.close()

        logger.info(f"DineBooking: '{matched_slot}' available for {party_size} at '{restaurant_name}'")
        return {
            "available": True,
            "confirmed_slot": matched_slot,
            "reason": "ok",
            "alternative_slots": [],
            "nearby_restaurants": [],
        }

    def confirm_booking(
        self,
        restaurant_id: str,
        restaurant_name: str,
        time_slot: str,
        party_size: int,
        date_str: Optional[str] = None,
        customer_name: Optional[str] = None,
        customer_phone: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Confirm a table booking by inserting it into the database with PENDING status.
        """
        db: Session = SessionLocal()
        try:
            valid_slots = _get_restaurant_slots(restaurant_id, db)
            matched_slot = _find_slot(time_slot, valid_slots) or time_slot
            date_str = date_str or datetime.utcnow().strftime("%d %b %Y")
            new_booking = Booking(
                restaurant_id=restaurant_id,
                party_size=party_size,
                time_slot=matched_slot,
                booking_date=date_str,
                customer_name=customer_name,
                customer_phone=customer_phone,
                status="PENDING"
            )
            db.add(new_booking)
            db.commit()
            db.refresh(new_booking)
            booking_id = str(new_booking.booking_id)
        except Exception as e:
            logger.error(f"Error saving booking to DB: {e}")
            db.rollback()
            booking_id = f"TBL{uuid.uuid4().hex[:8].upper()}" # Fallback
        finally:
            db.close()

        logger.info(f"DineBooking: confirmed {booking_id} at '{restaurant_name}' {matched_slot} for {party_size}")

        return {
            "booking_id": booking_id,
            "restaurant_id": restaurant_id,
            "restaurant_name": restaurant_name,
            "time_slot": matched_slot,
            "party_size": party_size,
            "date": date_str,
            "status": "PENDING",
        }

    def get_slots_availability(
        self,
        restaurant_id: str,
        date_str: str,
    ) -> List[Dict[str, Any]]:
        """
        Return a list of slots and whether they are available (capacity = max_dine_in_per_slot bookings per slot).
        """
        db: Session = SessionLocal()
        try:
            valid_slots = _get_restaurant_slots(restaurant_id, db)
            bookings = db.query(Booking).filter(
                Booking.restaurant_id == restaurant_id,
                Booking.booking_date == date_str,
                Booking.status.in_(["PENDING", "CONFIRMED"])
            ).all()

            restaurant = db.query(Restaurant).filter(Restaurant.restaurant_id == restaurant_id).first()
            max_dine_in_per_slot = getattr(restaurant, "max_dine_in_per_slot", 5) if restaurant else 5
            max_capacity = getattr(restaurant, "max_capacity", 100) if restaurant else 100

            # Group bookings by slot
            slot_booking_count = {s: 0 for s in valid_slots}
            slot_people_count = {s: 0 for s in valid_slots}
            for b in bookings:
                if b.time_slot in slot_booking_count:
                    slot_booking_count[b.time_slot] += 1
                    slot_people_count[b.time_slot] += b.party_size

            result = []
            for s in valid_slots:
                available = slot_booking_count[s] < max_dine_in_per_slot and slot_people_count[s] < max_capacity
                result.append({
                    "time_slot": s,
                    "available": available,
                    "seats_booked": slot_booking_count[s]
                })
            return result
        finally:
            db.close()

_service: Optional[DineBookingService] = None

def get_dine_booking_service() -> DineBookingService:
    global _service
    if _service is None:
        _service = DineBookingService()
    return _service
