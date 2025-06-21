from datetime import datetime

from pydantic import BaseModel, EmailStr

from database.models import Equipment, FitnessLevel, Goal


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
    fitness_level: FitnessLevel | None = None
    goals: list[Goal] | None = None
    equipment: Equipment | None = None
    injuries: list[str] | None = None
    preferences: dict | None = None


class ProgressMetricCreate(BaseModel):
    weight: float | None = None
    body_fat: float | None = None
    measurements: dict | None = None
    notes: str | None = None


class ProgressMetricResponse(BaseModel):
    id: str
    user_id: str
    date: datetime
    weight: float | None
    body_fat: float | None
    measurements: dict | None
    notes: str | None
    created_at: datetime
