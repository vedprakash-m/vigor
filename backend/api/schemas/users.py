from datetime import datetime

from pydantic import BaseModel, EmailStr

from database.models import Equipment, FitnessLevel, Goal
from typing import Optional


class UserProfileResponse(BaseModel):
    id: str
    email: EmailStr
    username: str
    fitness_level: FitnessLevel
    goals: list[Goal]
    equipment: Equipment
    injuries: list[str] = []
    preferences: dict = {}
    created_at: datetime
    updated_at: datetime


class UserProfileUpdate(BaseModel):
    """User profile update model"""

    fitness_level: Optional[FitnessLevel] = None
    goals: Optional[list[Goal]] = None
    equipment: Optional[Equipment] = None
    injuries: Optional[list[str]] = None
    preferences: Optional[dict] = None


class ProgressMetricCreate(BaseModel):
    weight: Optional[float] = None
    body_fat: Optional[float] = None
    measurements: Optional[dict] = None
    notes: Optional[str] = None


class ProgressMetricResponse(BaseModel):
    id: str
    user_id: str
    date: datetime
    weight: Optional[float]
    body_fat: Optional[float]
    measurements: Optional[dict]
    notes: Optional[str]
    created_at: datetime
