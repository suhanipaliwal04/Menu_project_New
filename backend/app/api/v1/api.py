"""
API Router - Combine all endpoint routers
"""
from fastapi import APIRouter

from app.api.v1.endpoints import areas, restaurants, menus, chat, admin, auth, voice, dine, bookings, orders

api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(auth.router,        prefix="/auth",        tags=["Auth"])
api_router.include_router(areas.router,       prefix="/areas",       tags=["Areas"])
api_router.include_router(restaurants.router, prefix="/restaurants", tags=["Restaurants"])
api_router.include_router(menus.router,       prefix="/menus",       tags=["Menus"])
api_router.include_router(chat.router,        prefix="/chat",        tags=["Chat"])
api_router.include_router(admin.router,       prefix="/admin",       tags=["Admin Dashboard"])
api_router.include_router(voice.router,       prefix="/voice",       tags=["Voice AI"])
api_router.include_router(dine.router,        prefix="/dine",        tags=["Dine-In Booking Voice"])
api_router.include_router(bookings.router,    prefix="/bookings",    tags=["Bookings REST"])
api_router.include_router(orders.router,      prefix="/orders",      tags=["Takeaway Orders"])
