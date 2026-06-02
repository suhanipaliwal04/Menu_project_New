"""
Auth API Endpoints

Provides:
 - POST /auth/admin-login — Supabase email/password sign-in that returns a JWT access token.
 - GET  /auth/me          — Returns the current authenticated user's profile.
"""
import uuid
import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.core.database import get_db
from app.core.auth import get_current_user
from app.core.config import settings
from app.models.restaurant import Restaurant
from app.schemas.auth import UserInfo

router = APIRouter()


# ─── Admin Login ──────────────────────────────────────────────────────────────

class AdminLoginRequest(BaseModel):
    email: str
    password: str


class AdminLoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    email: str


@router.post("/admin-login", response_model=AdminLoginResponse)
async def admin_login(body: AdminLoginRequest):
    """
    Authenticate with Supabase using email + password.
    Returns a JWT access_token that must be sent as:
        Authorization: Bearer <access_token>
    on all protected admin endpoints.
    """
    if not settings.SUPABASE_URL or not settings.SUPABASE_ANON_KEY:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Supabase is not configured on this server.",
        )

    sign_in_url = f"{settings.SUPABASE_URL}/auth/v1/token?grant_type=password"

    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                sign_in_url,
                json={"email": body.email, "password": body.password},
                headers={
                    "apikey": settings.SUPABASE_ANON_KEY,
                    "Content-Type": "application/json",
                },
                timeout=15.0,
            )
        except httpx.RequestError as e:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Could not reach Supabase: {e}",
            )

    if resp.status_code != 200:
        data = resp.json()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=data.get("error_description") or data.get("msg") or "Invalid credentials",
        )

    data = resp.json()
    return AdminLoginResponse(
        access_token=data["access_token"],
        user_id=data["user"]["id"],
        email=data["user"]["email"],
    )


@router.get("/me", response_model=UserInfo)
def get_me(
    current_user: uuid.UUID = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns the current authenticated user's info.

    If they own a restaurant, includes the restaurant_id and name.
    The frontend uses this to decide whether to show "Create Restaurant"
    or "Go to Dashboard".
    """
    # Check if user already owns a restaurant
    restaurant = db.query(Restaurant).filter(
        Restaurant.owner_id == current_user
    ).first()

    return UserInfo(
        user_id=current_user,
        restaurant_id=restaurant.restaurant_id if restaurant else None,
        restaurant_name=restaurant.restaurant_name if restaurant else None,
    )
