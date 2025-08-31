"""
Enhanced Pydantic models for the Vigor fitness platform
Compatible with Python 3.12+ using modern union syntax
"""

from datetime import date, datetime
from enum import Enum
from typing import Any
from uuid import uuid4

from pydantic import BaseModel, Field


class UserTier(str, Enum):
    """User subscription tiers with usage limits"""

    FREE = "free"
    PREMIUM = "premium"
    UNLIMITED = "unlimited"
    ENTERPRISE = "enterprise"


class Equipment(str, Enum):
    """Available workout equipment"""

    NONE = "none"
    MINIMAL = "minimal"
    MODERATE = "moderate"
    FULL = "full"
    DUMBBELLS = "dumbbells"
    BARBELL = "barbell"
    RESISTANCE_BANDS = "resistance_bands"
    PULL_UP_BAR = "pull_up_bar"
    FULL_GYM = "full_gym"


class FitnessLevel(str, Enum):
    """User fitness experience levels"""

    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    EXPERT = "expert"


class Goal(str, Enum):
    """User fitness goals"""

    WEIGHT_LOSS = "weight_loss"
    MUSCLE_GAIN = "muscle_gain"
    STRENGTH = "strength"
    ENDURANCE = "endurance"
    GENERAL_FITNESS = "general_fitness"
    FLEXIBILITY = "flexibility"
    ATHLETIC_PERFORMANCE = "athletic_performance"


class UserProfile(BaseModel):
    """Enhanced user profile with tier management and timestamps"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    email: str = Field(..., description="User's email address")
    username: str = Field(..., description="User's display name")
    hashed_password: str = Field(..., description="Hashed password")
    is_active: bool = Field(default=True, description="Account status")
    user_tier: UserTier = Field(default=UserTier.FREE, description="Subscription tier")
    tier_updated_at: datetime | None = None

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_login: datetime | None = None

    # Fitness profile
    fitness_level: FitnessLevel = Field(default=FitnessLevel.BEGINNER)
    goals: list[Goal] = Field(default_factory=list)
    equipment: list[Equipment] = Field(default_factory=list)
    available_equipment: list[Equipment] = Field(
        default_factory=list
    )  # Alias for compatibility


class WorkoutPlan(BaseModel):
    """AI-generated workout plan with metadata"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    user_id: str = Field(..., description="Owner of the workout plan")
    name: str = Field(..., description="Workout plan name")
    description: str = Field(..., description="Plan description")
    exercises: list[dict[str, Any]] = Field(default_factory=list)
    duration_minutes: int = Field(..., ge=5, le=300)
    difficulty_level: FitnessLevel
    equipment_needed: list[Equipment] = Field(default_factory=list)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class WorkoutLog(BaseModel):
    """User workout completion tracking"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    user_id: str = Field(..., description="User who completed the workout")
    plan_id: str | None = None
    workout_name: str = Field(..., description="Name of the workout")
    completed_at: datetime = Field(default_factory=datetime.utcnow)
    notes: str | None = None
    rating: int | None = Field(None, ge=1, le=5)

    # Exercise tracking
    exercises_completed: list[dict[str, Any]] = Field(default_factory=list)
    total_duration_minutes: int = Field(..., ge=1)


class ProgressMetrics(BaseModel):
    """User progress tracking and analytics"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    user_id: str = Field(..., description="User these metrics belong to")
    metric_date: date = Field(default_factory=date.today)

    # Workout metrics
    workouts_completed: int = Field(default=0, ge=0)
    total_workout_time_minutes: int = Field(default=0, ge=0)
    average_workout_rating: float | None = Field(None, ge=1.0, le=5.0)

    # Streak tracking
    current_streak_days: int = Field(default=0, ge=0)
    longest_streak_days: int = Field(default=0, ge=0)

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class AICoachMessage(BaseModel):
    """AI coach conversation tracking"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    user_id: str = Field(..., description="User in the conversation")
    message: str = Field(..., description="Message content")
    is_user_message: bool = Field(
        ..., description="True if from user, False if from AI"
    )
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    # AI metadata
    model_used: str | None = None
    tokens_used: int | None = None
    response_time_ms: int | None = None


class BudgetSettings(BaseModel):
    """Budget management for AI API usage"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    user_id: str = Field(..., description="User this budget applies to")

    # Budget limits (in USD)
    max_daily_cost: float | None = None
    max_weekly_cost: float | None = None
    max_monthly_cost: float | None = None

    # Current usage tracking
    daily_cost_used: float = Field(default=0.0, ge=0)
    weekly_cost_used: float = Field(default=0.0, ge=0)
    monthly_cost_used: float = Field(default=0.0, ge=0)

    # Metadata
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_reset_date: date = Field(default_factory=date.today)


class AIUsageLog(BaseModel):
    """Track AI/LLM API usage for cost management and analytics"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    user_id: str | None = None  # Track per-user usage
    provider: str = Field(..., description="AI provider used (openai, gemini, etc.)")
    model: str = Field(..., description="Specific model used")
    endpoint: str = Field(..., description="API endpoint called")
    tokens_used: int = Field(..., ge=0, description="Number of tokens consumed")
    cost_usd: float = Field(..., ge=0, description="Cost in USD")
    response_time_ms: int = Field(
        ..., ge=0, description="Response time in milliseconds"
    )
    success: bool = Field(..., description="Whether the request was successful")
    error_message: str | None = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

    # Additional metadata for debugging and optimization
    request_metadata: dict[str, Any] | None = None
    response_metadata: dict[str, Any] | None = None


class AdminSettings(BaseModel):
    """Admin configuration for LLM providers and budgets"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    setting_key: str = Field(..., description="Configuration key")
    setting_value: str = Field(..., description="Configuration value")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class BudgetUsage(BaseModel):
    """Current budget usage status"""

    user_id: str
    tier: UserTier
    daily_cost_used: float = 0.0
    weekly_cost_used: float = 0.0
    monthly_cost_used: float = 0.0
    last_reset_date: date | None = None

    daily_limit: float | None = None
    weekly_limit: float | None = None
    monthly_limit: float | None = None

    is_over_daily_limit: bool = False
    is_over_weekly_limit: bool = False
    is_over_monthly_limit: bool = False


class Exercise(BaseModel):
    """Individual exercise definition"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    name: str = Field(..., description="Exercise name")
    description: str | None = None
    muscle_groups: list[str] = Field(default_factory=list)
    equipment_needed: list[Equipment] = Field(default_factory=list)
    difficulty_level: FitnessLevel = Field(default=FitnessLevel.BEGINNER)
    instructions: str | None = None

    # Exercise parameters
    sets: int | None = None
    reps: int | None = None
    duration_seconds: int | None = None
    rest_seconds: int | None = None

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class AIProviderPriority(BaseModel):
    """AI provider priority configuration for admin management"""

    id: str = Field(default_factory=lambda: str(uuid4()))
    provider_name: str = Field(..., description="Provider name (openai, gemini, etc.)")
    model_name: str = Field(..., description="Specific model name")
    priority: int = Field(..., description="Priority order (1 = highest)")
    is_enabled: bool = Field(default=True, description="Whether provider is enabled")

    # Cost limits
    max_daily_cost: float | None = None
    max_weekly_cost: float | None = None
    max_monthly_cost: float | None = None

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
