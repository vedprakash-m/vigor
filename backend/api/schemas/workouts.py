from datetime import datetime
from typing import Dict, List, Optional

from pydantic import BaseModel, Field

from database.models import FitnessLevel


class Exercise(BaseModel):
    name: str
    sets: Optional[int] = None
    reps: Optional[str] = None  # Can be "8-12" or "30 seconds"
    weight: Optional[float] = None
    rest: Optional[str] = None  # e.g., "60 seconds"
    notes: Optional[str] = None


class WorkoutPlanCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: str
    exercises: List[Exercise]
    duration_minutes: int = Field(..., gt=0)
    equipment_needed: List[str] = []


class WorkoutPlanResponse(BaseModel):
    id: str
    user_id: str
    name: str
    description: str
    exercises: List[Dict]
    duration_minutes: int
    difficulty: FitnessLevel
    equipment_needed: List[str]
    created_at: datetime
    updated_at: datetime


class WorkoutLogCreate(BaseModel):
    plan_id: str
    duration_minutes: int = Field(..., gt=0)
    exercises: List[Exercise]
    notes: Optional[str] = None
    rating: Optional[int] = Field(None, ge=1, le=5)


class WorkoutLogResponse(BaseModel):
    id: str
    user_id: str
    plan_id: str
    completed_at: datetime
    duration_minutes: int
    exercises: List[Dict]
    notes: Optional[str]
    rating: Optional[int]
    created_at: datetime


class AIWorkoutRequest(BaseModel):
    goals: List[str]
    equipment: str
    duration_minutes: int = Field(default=45, ge=15, le=120)
    focus_areas: Optional[List[str]] = None
