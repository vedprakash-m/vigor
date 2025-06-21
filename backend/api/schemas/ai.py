from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)


class ChatResponse(BaseModel):
    response: str
    created_at: datetime


class WorkoutRecommendationRequest(BaseModel):
    """Request for workout recommendations"""

    # Optional overrides - use user's profile if not provided
    goals: Optional[List[str]] = None  # Use user's goals if not provided
    fitness_level: Optional[str] = None  # Use user's fitness level if not provided
    equipment: Optional[str] = None  # Use user's equipment if not provided
    focus_areas: Optional[List[str]] = None


class WorkoutSessionRequest(BaseModel):
    """Request for workout session generation"""

    workout_plan_id: str
    session_number: int
    notes: Optional[str] = None


class ChatRequest(BaseModel):
    """Request for AI chat/coaching"""

    message: str
    conversation_id: Optional[str] = None
    context: Optional[Dict[str, Any]] = None


class GeneratedWorkoutPlan(BaseModel):
    name: str
    description: str
    exercises: List[dict]
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
