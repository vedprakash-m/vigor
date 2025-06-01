from datetime import datetime
from typing import Dict, List, Optional

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)


class ChatResponse(BaseModel):
    response: str
    created_at: datetime


class WorkoutRecommendationRequest(BaseModel):
    goals: Optional[List[str]] = None  # Use user's goals if not provided
    equipment: Optional[str] = None  # Use user's equipment if not provided
    duration_minutes: int = Field(default=45, ge=15, le=120)
    focus_areas: Optional[List[str]] = None


class GeneratedWorkoutPlan(BaseModel):
    name: str
    description: str
    exercises: List[Dict]
    duration_minutes: int
    difficulty: str
    equipment_needed: List[str]
    notes: Optional[str] = None


class WorkoutAnalysis(BaseModel):
    overall_assessment: str
    strengths: List[str]
    areas_for_improvement: List[str]
    recommendations: List[str]
    next_steps: str
