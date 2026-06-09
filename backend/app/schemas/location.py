from pydantic import BaseModel
import uuid
from typing import List

class LocationStateBase(BaseModel):
    state_name: str

class LocationStateCreate(LocationStateBase):
    pass

class LocationStateResponse(LocationStateBase):
    state_id: uuid.UUID

    class Config:
        orm_mode = True

class LocationCityBase(BaseModel):
    city_name: str
    state_id: uuid.UUID

class LocationCityCreate(LocationCityBase):
    pass

class LocationCityResponse(LocationCityBase):
    city_id: uuid.UUID

    class Config:
        orm_mode = True

class StateWithCitiesResponse(LocationStateResponse):
    cities: List[LocationCityResponse] = []
