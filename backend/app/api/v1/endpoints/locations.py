import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.auth import get_current_user
from app.models.user import User
from app.models.location import LocationState, LocationCity
from app.schemas.location import LocationStateCreate, LocationStateResponse, LocationCityCreate, LocationCityResponse

router = APIRouter()

def require_system_admin(db: Session, current_user: uuid.UUID) -> User:
    user = db.query(User).filter(User.user_id == current_user).first()
    if not user or user.role != "SYSTEM_ADMIN":
        raise HTTPException(status_code=403, detail="System Admin access required.")
    return user

@router.get("/states", response_model=List[LocationStateResponse])
def get_states(db: Session = Depends(get_db)):
    """Fetch all functional states."""
    states = db.query(LocationState).order_by(LocationState.state_name).all()
    return states

@router.post("/states", response_model=LocationStateResponse)
def create_state(
    data: LocationStateCreate,
    current_user: uuid.UUID = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new functional state (Admin only)."""
    require_system_admin(db, current_user)
    
    existing = db.query(LocationState).filter(LocationState.state_name.ilike(data.state_name)).first()
    if existing:
        raise HTTPException(status_code=400, detail="State already exists.")
        
    new_state = LocationState(state_name=data.state_name)
    db.add(new_state)
    db.commit()
    db.refresh(new_state)
    return new_state

@router.get("/states/{state_name}/cities", response_model=List[LocationCityResponse])
def get_cities(state_name: str, db: Session = Depends(get_db)):
    """Fetch cities for a given state name."""
    state = db.query(LocationState).filter(LocationState.state_name.ilike(state_name)).first()
    if not state:
        return []
    cities = db.query(LocationCity).filter(LocationCity.state_id == state.state_id).order_by(LocationCity.city_name).all()
    return cities

@router.post("/cities", response_model=LocationCityResponse)
def create_city(
    data: LocationCityCreate,
    current_user: uuid.UUID = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new functional city (Admin only)."""
    require_system_admin(db, current_user)
    
    state = db.query(LocationState).filter(LocationState.state_id == data.state_id).first()
    if not state:
        raise HTTPException(status_code=404, detail="State not found.")
        
    existing = db.query(LocationCity).filter(
        LocationCity.city_name.ilike(data.city_name),
        LocationCity.state_id == data.state_id
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="City already exists in this state.")
        
    new_city = LocationCity(city_name=data.city_name, state_id=data.state_id)
    db.add(new_city)
    db.commit()
    db.refresh(new_city)
    return new_city
