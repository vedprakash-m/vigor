from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    context: dict[str, Any] | None = None


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
    model_used: str | None = None
    tokens_used: int | None = None
    response_time_ms: int | None = None


class LLMRequest(BaseModel):
    """LLM request schema for API endpoints"""

    prompt: str
    user_id: str | None = None
    session_id: str | None = None
    task_type: str | None = None
    max_tokens: int | None = None
    temperature: float | None = None
    stream: bool = False
    context: dict[str, Any] | None = None
    metadata: dict[str, Any] | None = None


class WorkoutRecommendationRequest(BaseModel):
    """Request for workout recommendations"""

    # Optional overrides - use user's profile if not provided
    goals: list[str] | None = None  # Use user's goals if not provided
    fitness_level: str | None = None  # Use user's fitness level if not provided
    equipment: str | None = None  # Use user's equipment if not provided
    focus_areas: list[str] | None = None
    duration_minutes: int | None = Field(None, ge=5, le=300)  # Workout duration


class WorkoutSessionRequest(BaseModel):
    """Request for workout session generation"""

    workout_plan_id: str
    session_number: int
    notes: str | None = None


class ChatRequest(BaseModel):
    """Request for AI chat/coaching"""

    message: str
    conversation_id: str | None = None
    context: dict[str, Any] | None = None


class WorkoutAnalysisRequest(BaseModel):
    """Request for workout analysis with body data"""

    workout_data: str = Field(
        ..., min_length=1, max_length=5000, description="Workout data to analyze"
    )
    analysis_type: str | None = Field(
        "performance", description="Type of analysis to perform"
    )
    include_recommendations: bool = Field(
        True, description="Whether to include recommendations"
    )
    workout_log_id: str | None = Field(
        None, description="Optional workout log ID if analyzing existing log"
    )


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
