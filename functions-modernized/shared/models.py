"""
Data models for Vigor Functions
Pydantic models for request/response validation and Cosmos DB documents
"""

from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, EmailStr, Field

# =============================================================================
# ENUMS
# =============================================================================


class FitnessLevel(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class UserTier(str, Enum):
    FREE = "free"
    ADMIN = "admin"


class WorkoutDifficulty(str, Enum):
    EASY = "easy"
    MODERATE = "moderate"
    HARD = "hard"
    EXTREME = "extreme"


# =============================================================================
# USER MODELS
# =============================================================================


class UserProfileData(BaseModel):
    """User profile information"""

    fitnessLevel: FitnessLevel = FitnessLevel.BEGINNER
    goals: List[str] = Field(default_factory=list)
    equipment: str = "bodyweight"
    tier: UserTier = UserTier.FREE


class UserPreferences(BaseModel):
    """User preferences for workouts and app behavior"""

    workoutDuration: int = Field(default=45, ge=15, le=120)
    restDays: List[str] = Field(default_factory=list)
    notifications: bool = True


class UserProfile(BaseModel):
    """Complete user profile document"""

    id: str
    userId: str  # Partition key
    email: EmailStr
    username: Optional[str] = None
    profile: UserProfileData
    preferences: UserPreferences
    createdAt: datetime
    updatedAt: datetime = Field(default_factory=datetime.utcnow)


class User(BaseModel):
    """User document for Cosmos DB with email as primary key"""

    id: str  # Email address as primary key
    email: EmailStr
    username: str
    tier: UserTier = UserTier.FREE
    fitness_level: FitnessLevel = FitnessLevel.BEGINNER
    fitness_goals: List[str] = Field(default_factory=lambda: ["general_fitness"])
    available_equipment: List[str] = Field(default_factory=lambda: ["none"])
    injury_history: List[str] = Field(default_factory=list)
    created_at: str
    updated_at: str


# =============================================================================
# WORKOUT MODELS
# =============================================================================


class Exercise(BaseModel):
    """Individual exercise within a workout"""

    name: str
    sets: int = Field(ge=1, le=10)
    reps: Optional[int] = None
    duration: Optional[int] = None  # Duration in seconds
    restTime: int = Field(default=60, ge=0, le=300)
    equipment: str = "bodyweight"
    instructions: Optional[str] = None


class WorkoutMetadata(BaseModel):
    """Metadata for workout plans"""

    difficulty: str
    estimatedDuration: int  # Minutes
    equipmentNeeded: List[str] = Field(default_factory=list)
    aiProviderUsed: str = "azure-openai-gpt-5-mini"
    tags: List[str] = Field(default_factory=list)


class WorkoutPlan(BaseModel):
    """Workout plan document"""

    id: str
    userId: str  # Partition key
    name: str
    description: Optional[str] = None
    exercises: List[Exercise]
    metadata: WorkoutMetadata
    createdAt: datetime = Field(default_factory=datetime.utcnow)


class ExerciseLog(BaseModel):
    """Log of completed exercise"""

    exerciseName: str
    completedSets: int
    actualReps: List[int] = Field(default_factory=list)
    actualDuration: Optional[int] = None
    notes: Optional[str] = None


class WorkoutLog(BaseModel):
    """Workout session log document"""

    id: str
    userId: str  # Partition key
    workoutPlanId: Optional[str] = None
    exercisesCompleted: List[ExerciseLog]
    durationMinutes: int
    intensity: int = Field(ge=1, le=10)  # User-rated intensity
    notes: Optional[str] = None
    completedAt: datetime = Field(default_factory=datetime.utcnow)


# =============================================================================
# AI MODELS
# =============================================================================


class AICoachMessage(BaseModel):
    """AI coach conversation message"""

    id: str
    userId: str  # Partition key
    role: str  # 'user' or 'assistant'
    content: str
    providerUsed: str = "azure-openai-gpt-5-mini"
    tokensUsed: Optional[int] = None
    responseTimeMs: Optional[int] = None
    createdAt: datetime = Field(default_factory=datetime.utcnow)


# =============================================================================
# REQUEST/RESPONSE MODELS
# =============================================================================


class WorkoutGenerationRequest(BaseModel):
    """Request for workout generation"""

    fitnessLevel: Optional[FitnessLevel] = None
    goals: Optional[List[str]] = None
    equipment: Optional[str] = None
    durationMinutes: int = Field(default=45, ge=15, le=120)
    focusAreas: Optional[List[str]] = None
    difficulty: Optional[WorkoutDifficulty] = None


class CoachChatRequest(BaseModel):
    """Request for AI coach chat"""

    message: str = Field(min_length=1, max_length=1000)
    context: Optional[Dict[str, Any]] = None


class WorkoutSessionRequest(BaseModel):
    """Request to log workout session"""

    workoutPlanId: Optional[str] = None
    exercises: List[ExerciseLog]
    durationMinutes: int = Field(ge=1, le=300)
    intensity: int = Field(ge=1, le=10)
    notes: Optional[str] = None


# =============================================================================
# RESPONSE MODELS
# =============================================================================


class ApiResponse(BaseModel):
    """Standard API response wrapper"""

    success: bool = True
    data: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class PaginatedResponse(BaseModel):
    """Paginated response for list endpoints"""

    items: List[Dict[str, Any]]
    total: int
    page: int
    pageSize: int
    hasNext: bool


class HealthCheckResponse(BaseModel):
    """Health check response"""

    status: str
    timestamp: datetime
    services: Dict[str, str]
    version: str


# =============================================================================
# COST MANAGEMENT MODELS
# =============================================================================


class BudgetStatus(BaseModel):
    """AI budget status"""

    approved: bool
    currentSpend: float
    dailyBudget: float
    monthlyBudget: float
    reason: Optional[str] = None


class CostMetrics(BaseModel):
    """Cost tracking metrics"""

    dailySpend: float
    monthlySpend: float
    requestsToday: int
    requestsThisMonth: int
    averageCostPerRequest: float
