from datetime import datetime

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)


class ChatResponse(BaseModel):
    response: str
    created_at: datetime


class WorkoutRecommendationRequest(BaseModel):
    goals: list[str] | None = None  # Use user's goals if not provided
    equipment: str | None = None  # Use user's equipment if not provided
    duration_minutes: int = Field(default=45, ge=15, le=120)
    focus_areas: list[str] | None = None


class GeneratedWorkoutPlan(BaseModel):
    name: str
    description: str
    exercises: list[dict]
    duration_minutes: int
    difficulty: str
    equipment_needed: list[str]
    notes: str | None = None


class WorkoutAnalysis(BaseModel):
    overall_assessment: str
    strengths: list[str]
    areas_for_improvement: list[str]
    recommendations: list[str]
    next_steps: str
