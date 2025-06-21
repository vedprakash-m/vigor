from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    context: Optional[dict[str, Any]] = None


class ChatResponse(BaseModel):
    response: str
    created_at: datetime = Field(default_factory=datetime.utcnow)


class AICoachMessage(BaseModel):
    """AI coach message for conversation tracking"""

    id: str
    user_id: str
    message: str
    is_user_message: bool
    timestamp: datetime
    model_used: Optional[str] = None
    tokens_used: Optional[int] = None
    response_time_ms: Optional[int] = None


class LLMRequest(BaseModel):
    """LLM request schema for API endpoints"""

    prompt: str
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    task_type: Optional[str] = None
    max_tokens: Optional[int] = None
    temperature: Optional[float] = None
    stream: bool = False
    context: Optional[dict[str, Any]] = None
    metadata: Optional[dict[str, Any]] = None


class WorkoutRecommendationRequest(BaseModel):
    """Request for workout recommendations"""

    # Optional overrides - use user's profile if not provided
    goals: Optional[list[str]] = None  # Use user's goals if not provided
    fitness_level: Optional[str] = None  # Use user's fitness level if not provided
    equipment: Optional[str] = None  # Use user's equipment if not provided
    focus_areas: Optional[list[str]] = None
    duration_minutes: Optional[int] = Field(None, ge=5, le=300)  # Workout duration


class WorkoutSessionRequest(BaseModel):
    """Request for workout session generation"""

    workout_plan_id: str
    session_number: int
    notes: Optional[str] = None


class ChatRequest(BaseModel):
    """Request for AI chat/coaching"""

    message: str
    conversation_id: Optional[str] = None
    context: Optional[dict[str, Any]] = None


class GeneratedWorkoutPlan(BaseModel):
    name: str
    description: str
    exercises: list[dict]
    duration_minutes: int
    difficulty: str
    equipment_needed: list[str]
    notes: Optional[str] = None


class WorkoutAnalysis(BaseModel):
    overall_assessment: str
    strengths: list[str]
    areas_for_improvement: list[str]
    recommendations: list[str]
    next_steps: str
