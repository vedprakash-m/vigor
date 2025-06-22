"""
Workout-related schemas and data models
"""

from datetime import datetime

from pydantic import BaseModel, Field

from database.models import FitnessLevel


class ExerciseSet(BaseModel):
    """Individual exercise set"""

    reps: str | None = None  # Can be "8-12" or "30 seconds"
    weight: float | None = None  # Weight in lbs/kg
    rest: str | None = None  # e.g., "60 seconds"
    notes: str | None = None


class Exercise(BaseModel):
    """Individual exercise in a workout"""

    name: str
    muscle_groups: list[str]
    sets: list[ExerciseSet]
    instructions: str | None = None


class WorkoutPlan(BaseModel):
    """Complete workout plan"""

    name: str
    description: str
    exercises: list[Exercise]
    estimated_duration_minutes: int = Field(..., gt=0)
    difficulty_level: str = Field(..., pattern="^(beginner|intermediate|advanced)$")
    equipment_needed: list[str] = []
    notes: str | None = None


class WorkoutSession(BaseModel):
    """Individual workout session/log"""

    workout_plan_id: str
    date: datetime
    duration_minutes: int
    exercises_completed: list[Exercise]
    notes: str | None = None


class WorkoutPlanRequest(BaseModel):
    """Request to generate a workout plan"""

    goals: list[str]
    fitness_level: str
    available_equipment: list[str]
    duration_minutes: int = Field(default=45, ge=15, le=120)
    focus_areas: list[str] | None = None
    notes: str | None = None


class WorkoutPlanCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: str
    exercises: list[Exercise]
    duration_minutes: int = Field(..., gt=0)
    equipment_needed: list[str] = []


class WorkoutPlanResponse(BaseModel):
    id: str
    user_id: str
    name: str
    description: str
    exercises: list[dict]
    duration_minutes: int
    difficulty: FitnessLevel
    equipment_needed: list[str]
    created_at: datetime
    updated_at: datetime


class WorkoutLogCreate(BaseModel):
    plan_id: str
    duration_minutes: int = Field(..., gt=0)
    exercises: list[Exercise]
    notes: str | None = None
    rating: int | None = Field(None, ge=1, le=5)


class WorkoutLogResponse(BaseModel):
    id: str
    user_id: str
    plan_id: str
    completed_at: datetime
    duration_minutes: int
    exercises: list[dict]
    notes: str | None
    rating: int | None
    created_at: datetime


class AIWorkoutRequest(BaseModel):
    goals: list[str]
    equipment: str
    duration_minutes: int = Field(default=45, ge=15, le=120)
    focus_areas: list[str] | None = None
