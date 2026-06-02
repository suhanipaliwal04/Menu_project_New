"""
Dine-In Booking Endpoints
──────────────────────────
POST /api/v1/dine/check-availability
    Checks if a table is available for a given restaurant, time slot, and party size.
    Returns available slots or nearby restaurants if the request cannot be fulfilled.

POST /api/v1/dine/confirm-booking
    Confirms a table booking and returns a booking record with a unique ID.

These endpoints are intentionally LLM-free — they respond in <100ms
and are designed to be called concurrently with TTS playback on the client.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.services.dine.dine_booking_service import get_dine_booking_service

router = APIRouter()


# ── Schemas ───────────────────────────────────────────────────────────────────

class AvailabilityRequest(BaseModel):
    restaurant_id: str = Field(..., description="UUID of the restaurant to check.")
    restaurant_name: str = Field("", description="Display name (used in response text).")
    time_slot: str = Field(..., description="Requested time, e.g. '7:00 PM', '7pm', '19:00'.")
    party_size: int = Field(..., ge=1, le=50, description="Number of guests.")


class NearbyRestaurant(BaseModel):
    id: str
    name: str
    cuisine: str
    area: str
    rating: float


class AvailabilityResponse(BaseModel):
    available: bool
    confirmed_slot: Optional[str]
    reason: str = Field(..., description="'ok' | 'time_unavailable' | 'seats_unavailable'")
    alternative_slots: List[str] = Field(default_factory=list)
    nearby_restaurants: List[NearbyRestaurant] = Field(default_factory=list)
    ai_message: str = Field(..., description="Pre-built voice-ready message for the AI to speak.")


class BookingRequest(BaseModel):
    restaurant_id: str
    restaurant_name: str = ""
    time_slot: str
    party_size: int = Field(..., ge=1, le=50)
    date_str: Optional[str] = None


class BookingConfirmation(BaseModel):
    booking_id: str
    restaurant_id: str
    restaurant_name: str
    time_slot: str
    party_size: int
    date: str
    status: str
    ai_message: str = Field(..., description="Voice-ready confirmation message.")


# ── Helper — build voice messages ─────────────────────────────────────────────

def _build_availability_message(result: Dict[str, Any], restaurant_name: str, party_size: int, requested_slot: str) -> str:
    reason = result["reason"]
    name = restaurant_name or "this restaurant"

    if reason == "ok":
        return (
            f"Great news! I found a table for {party_size} at {name} at {result['confirmed_slot']}. "
            "Shall I confirm the booking?"
        )

    if reason == "time_unavailable":
        slots = result["alternative_slots"]
        if slots:
            slot_list = ", ".join(slots[:4])
            return (
                f"Sorry, {requested_slot} isn't available at {name}. "
                f"Here are some open slots: {slot_list}. Which time works for you?"
            )
        return f"Sorry, no tables are currently available at {name}. Please try a different time."

    if reason == "seats_unavailable":
        nearby = result["nearby_restaurants"]
        if nearby:
            names = ", ".join(r["name"] for r in nearby[:3])
            return (
                f"Sorry, there's no table for {party_size} people available at {name} right now. "
                f"Here are some nearby restaurants with availability: {names}. "
                "Would you like me to book at one of these?"
            )
        return (
            f"Sorry, no table for {party_size} people is available at {name}. "
            "Please try a smaller party size or a different time."
        )

    return "I couldn't check availability right now. Please try again."


def _build_confirmation_message(booking: Dict[str, Any]) -> str:
    return (
        f"Your reservation has been made successfully! "
        f"Booking ID {booking['booking_id']} — "
        f"Table for {booking['party_size']} at {booking['restaurant_name']}, "
        f"{booking['time_slot']} on {booking['date']}. Enjoy your meal!"
    )


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post(
    "/check-availability",
    response_model=AvailabilityResponse,
    summary="Check dine-in table availability",
    description="Fast LLM-free check: is a table available for the given party size and time?",
)
async def check_availability(req: AvailabilityRequest):
    """
    Check availability and return a voice-ready message + structured data.
    Called concurrently with TTS on the client to eliminate latency.
    """
    svc = get_dine_booking_service()
    result = svc.check_availability(
        restaurant_id=req.restaurant_id,
        restaurant_name=req.restaurant_name,
        time_slot=req.time_slot,
        party_size=req.party_size,
    )

    ai_message = _build_availability_message(
        result=result,
        restaurant_name=req.restaurant_name,
        party_size=req.party_size,
        requested_slot=req.time_slot,
    )

    return AvailabilityResponse(
        available=result["available"],
        confirmed_slot=result.get("confirmed_slot"),
        reason=result["reason"],
        alternative_slots=result.get("alternative_slots", []),
        nearby_restaurants=[
            NearbyRestaurant(**r) for r in result.get("nearby_restaurants", [])
        ],
        ai_message=ai_message,
    )


@router.post(
    "/confirm-booking",
    response_model=BookingConfirmation,
    summary="Confirm a dine-in table booking",
    description="Confirms the reservation and returns a booking record with ID.",
    status_code=201,
)
async def confirm_booking(req: BookingRequest):
    """
    Confirm and persist the booking. Returns booking details + voice confirmation message.
    """
    svc = get_dine_booking_service()
    booking = svc.confirm_booking(
        restaurant_id=req.restaurant_id,
        restaurant_name=req.restaurant_name,
        time_slot=req.time_slot,
        party_size=req.party_size,
        date_str=req.date_str,
    )

    return BookingConfirmation(
        **booking,
        ai_message=_build_confirmation_message(booking),
    )
