"""
Auth API Endpoints

Provides:
 - POST /auth/register/{role} — Supabase email/password sign-up and local role creation.
 - POST /auth/login           — Supabase email/password sign-in with strict role checks.
 - GET  /auth/me              — Returns the current authenticated user's profile and role.
"""
import uuid
import httpx
from fastapi import APIRouter, Depends, HTTPException, status, Path
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.core.database import get_db
from app.core.auth import get_current_user
from app.core.config import settings
from app.models.restaurant import Restaurant
from app.models.user import User
from app.schemas.auth import UserInfo

router = APIRouter()


class RegisterRequest(BaseModel):
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str
    expected_role: str  # 'SYSTEM_ADMIN', 'RESTAURANT_ADMIN', 'CUSTOMER'


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    email: str
    role: str
    is_approved: bool


@router.post("/register/{role}")
async def register(
    body: RegisterRequest, 
    role: str = Path(..., description="Role must be 'customer' or 'restaurant-admin'"),
    db: Session = Depends(get_db)
):
    """
    Sign up a new user via Supabase and assign them a role in the local database.
    Customers are auto-approved. Restaurant Admins require System Admin approval.
    """
    if role not in ["customer", "restaurant-admin"]:
        raise HTTPException(status_code=400, detail="Invalid role for registration.")

    if not settings.SUPABASE_URL or not settings.SUPABASE_ANON_KEY:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Supabase is not configured on this server.",
        )

    db_role = "CUSTOMER" if role == "customer" else "RESTAURANT_ADMIN"
    is_approved = True if db_role == "CUSTOMER" else False

    sign_up_url = f"{settings.SUPABASE_URL}/auth/v1/signup"

    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                sign_up_url,
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
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=data.get("msg") or "Registration failed",
        )

    data = resp.json()
    user_id = data.get("user", {}).get("id") or data.get("id")

    if not user_id:
        raise HTTPException(status_code=500, detail="Supabase registration succeeded but no user ID returned.")

    # Create local user record
    # Note: if the email already exists in Supabase, Supabase might just return 200 with no user if "confirm email" is on, 
    # but let's assume auto-confirm is enabled or we get the user_id.
    
    # Check if user already exists locally (in case of re-registration)
    existing_user = db.query(User).filter(User.user_id == uuid.UUID(user_id)).first()
    if not existing_user:
        new_user = User(
            user_id=uuid.UUID(user_id),
            email=body.email,
            role=db_role,
            is_approved=is_approved
        )
        db.add(new_user)
        try:
            db.commit()
        except Exception as e:
            db.rollback()
            if "ix_users_email" in str(e) or "unique constraint" in str(e).lower():
                raise HTTPException(status_code=400, detail="This email is already registered. Please login instead or use a different email.")
            raise HTTPException(status_code=500, detail=f"Failed to create local user record: {e}")

    return {
        "message": "Registration successful",
        "user_id": user_id,
        "role": db_role,
        "is_approved": is_approved
    }


@router.post("/login", response_model=LoginResponse)
async def login(body: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate with Supabase using email + password, and check the role.
    """
    if body.expected_role not in ["SYSTEM_ADMIN", "RESTAURANT_ADMIN", "CUSTOMER"]:
        raise HTTPException(status_code=400, detail="Invalid expected role.")

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
    user_id = data["user"]["id"]
    email = data["user"]["email"]

    # Verify role
    local_user = db.query(User).filter(User.user_id == uuid.UUID(user_id)).first()
    
    if not local_user:
        # Fallback for old system admins if they are not in the users table yet
        # If it's the specific test email, we can let it pass, but better to insert them
        if body.expected_role == "SYSTEM_ADMIN" and email == "admin@eatbot.com":
            local_user = User(user_id=uuid.UUID(user_id), email=email, role="SYSTEM_ADMIN", is_approved=True)
            db.add(local_user)
            db.commit()
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User record not found in local database."
            )

    if local_user.role != body.expected_role:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access denied. You do not have the {body.expected_role} role."
        )

    if not local_user.is_approved:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account is pending approval by a System Administrator."
        )

    return LoginResponse(
        access_token=data["access_token"],
        user_id=user_id,
        email=email,
        role=local_user.role,
        is_approved=local_user.is_approved
    )


@router.get("/me", response_model=UserInfo)
def get_me(
    current_user: uuid.UUID = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Returns the current authenticated user's info.
    """
    restaurant = db.query(Restaurant).filter(
        Restaurant.owner_id == current_user
    ).first()

    with open("debug.log", "a") as f:
        f.write(f"GET ME CALLED! current_user: {current_user}, restaurant: {restaurant.restaurant_id if restaurant else None}\n")

    return UserInfo(
        user_id=current_user,
        restaurant_id=restaurant.restaurant_id if restaurant else None,
        restaurant_name=restaurant.restaurant_name if restaurant else None,
    )
