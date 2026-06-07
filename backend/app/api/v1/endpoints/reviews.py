"""
Reviews API Endpoints
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import uuid

from app.core.database import get_db
from app.models.review import RestaurantReview, AppReview
from app.models.restaurant import Restaurant
from app.schemas.review import RestaurantReviewCreate, RestaurantReviewResponse, AppReviewCreate, AppReviewResponse

router = APIRouter()

# ═══════════════════════════════════════════════════════════════════════════════
# RESTAURANT REVIEWS
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/restaurant", response_model=RestaurantReviewResponse)
def create_restaurant_review(review: RestaurantReviewCreate, db: Session = Depends(get_db)):
    """Create a new restaurant review"""
    # Verify restaurant exists
    restaurant = db.query(Restaurant).filter(Restaurant.restaurant_id == review.restaurant_id).first()
    if not restaurant:
        raise HTTPException(status_code=404, detail="Restaurant not found")

    db_review = RestaurantReview(
        restaurant_id=review.restaurant_id,
        rating=review.rating,
        review_text=review.review_text,
        customer_name=review.customer_name
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review

@router.get("/restaurant/{restaurant_id}", response_model=List[RestaurantReviewResponse])
def get_restaurant_reviews(restaurant_id: uuid.UUID, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get reviews for a specific restaurant"""
    reviews = db.query(RestaurantReview).filter(
        RestaurantReview.restaurant_id == restaurant_id
    ).order_by(RestaurantReview.created_at.desc()).offset(skip).limit(limit).all()
    return reviews

@router.delete("/restaurant/{restaurant_id}")
def clear_restaurant_reviews(restaurant_id: uuid.UUID, db: Session = Depends(get_db)):
    """Clear all reviews for a specific restaurant"""
    db.query(RestaurantReview).filter(RestaurantReview.restaurant_id == restaurant_id).delete()
    db.commit()
    return {"detail": "Restaurant reviews cleared successfully"}

# ═══════════════════════════════════════════════════════════════════════════════
# APP REVIEWS
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/app", response_model=AppReviewResponse)
def create_app_review(review: AppReviewCreate, db: Session = Depends(get_db)):
    """Create a new app review"""
    db_review = AppReview(
        rating=review.rating,
        review_text=review.review_text,
        customer_name=review.customer_name
    )
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review

@router.get("/app", response_model=List[AppReviewResponse])
def get_app_reviews(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all app reviews"""
    reviews = db.query(AppReview).order_by(AppReview.created_at.desc()).offset(skip).limit(limit).all()
    return reviews

@router.delete("/app")
def clear_app_reviews(db: Session = Depends(get_db)):
    """Clear all app reviews"""
    db.query(AppReview).delete()
    db.commit()
    return {"detail": "App reviews cleared successfully"}
