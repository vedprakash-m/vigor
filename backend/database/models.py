from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class FitnessLevel(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class Goal(str, Enum):
    WEIGHT_LOSS = "weight_loss"
    MUSCLE_GAIN = "muscle_gain"
    ENDURANCE = "endurance"
    FLEXIBILITY = "flexibility"
    GENERAL_FITNESS = "general_fitness"


class Equipment(str, Enum):
    NONE = "none"
    MINIMAL = "minimal"  # Dumbbells, resistance bands
    MODERATE = "moderate"  # Basic home gym
    FULL = "full"  # Full gym access


class UserProfile(BaseModel):
    id: str
    email: str
    username: str
    fitness_level: FitnessLevel
    goals: List[Goal]
    equipment: Equipment
    injuries: List[str] = []
    preferences: Dict[str, Any] = {}
    created_at: datetime
    updated_at: datetime


class WorkoutPlan(BaseModel):
    id: str
    user_id: str
    name: str
    description: str
    exercises: List[Dict[str, Any]]
    duration_minutes: int
    difficulty: FitnessLevel
    equipment_needed: List[str]
    created_at: datetime
    updated_at: datetime


class WorkoutLog(BaseModel):
    id: str
    user_id: str
    workout_plan_id: Optional[str] = None
    exercises_completed: List[Dict[str, Any]]
    duration_minutes: int
    notes: Optional[str] = None
    completed_at: datetime


class ProgressMetrics(BaseModel):
    id: str
    user_id: str
    date: datetime
    weight: Optional[float]
    body_fat: Optional[float]
    measurements: Optional[dict]
    notes: Optional[str]
    created_at: datetime = Field(default_factory=datetime.utcnow)


class AICoachMessage(BaseModel):
    id: str
    user_id: str
    message: str
    response: str
    context: Optional[dict]
    created_at: datetime = Field(default_factory=datetime.utcnow)


class ChatMessage(BaseModel):
    id: str
    user_id: str
    message: str
    response: str
    created_at: datetime


class AIProviderPriority(BaseModel):
    model_config = {"protected_namespaces": ()}  # Allow model_ fields
    
    id: str
    provider_name: str  # openai, gemini, perplexity
    model_name: str  # gpt-4o, gemini-2.5-flash, etc.
    priority: int = 1  # 1 = highest priority
    is_enabled: bool = True
    max_daily_cost: Optional[float] = None
    max_weekly_cost: Optional[float] = None
    max_monthly_cost: Optional[float] = None
    created_at: datetime
    updated_at: datetime


class BudgetSettings(BaseModel):
    id: str
    total_weekly_budget: float  # dollars
    total_monthly_budget: float  # dollars
    alert_threshold_percentage: float = 80.0  # alert when 80% of budget used
    auto_disable_on_budget_exceeded: bool = True
    created_at: datetime
    updated_at: datetime


class AIUsageLog(BaseModel):
    model_config = {"protected_namespaces": ()}  # Allow model_ fields
    
    id: str
    user_id: Optional[str]  # Track per-user usage
    provider_name: str  # openai, gemini, perplexity
    model_name: str  # specific model used
    endpoint: str  # chat, completion, etc.
    input_tokens: int
    output_tokens: int
    cost: float  # calculated cost in USD
    response_time_ms: int
    success: bool
    error_message: Optional[str] = None
    created_at: datetime


class AdminSettings(BaseModel):
    id: str
    key: str  # setting name
    value: str  # JSON string for complex values
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime
