"""
Data models for Vigor Functions
Pydantic models for request/response validation and Cosmos DB documents
"""

from datetime import datetime, timezone
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


class UserProfileUpdate(BaseModel):
    """Allowed fields for profile updates.

    Blocks sensitive fields like ``tier``, ``email``, and ``id`` to prevent
    privilege escalation via ``PUT /users/profile``.
    """

    username: Optional[str] = Field(default=None, max_length=100)
    fitness_level: Optional[FitnessLevel] = None
    fitness_goals: Optional[List[str]] = None
    available_equipment: Optional[List[str]] = None
    injury_history: Optional[List[str]] = None
    preferences: Optional[UserPreferences] = None


class UserProfile(BaseModel):
    """Complete user profile document"""

    id: str
    userId: str  # Partition key
    email: EmailStr
    username: Optional[str] = None
    profile: UserProfileData
    preferences: UserPreferences
    createdAt: datetime
    updatedAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


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
    createdAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


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
    completedAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


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
    createdAt: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


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


class WorkoutContextRequest(BaseModel):
    """Request for workout recommendation (iOS WorkoutContext contract)"""

    recentWorkouts: Optional[List[Dict[str, Any]]] = Field(default_factory=list)
    sleepData: Optional[Dict[str, Any]] = None
    hrvData: Optional[Dict[str, Any]] = None
    trustPhase: Optional[str] = None
    availableWindows: List[Dict[str, Any]] = Field(default_factory=list)
    suggestedDuration: int = Field(default=45, ge=15, le=120)
    preferences: Optional[Dict[str, Any]] = None


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
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


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


# =============================================================================
# WORKOUT SAFETY VALIDATION
# =============================================================================


class WorkoutSafetyValidator:
    """Validates AI-generated workouts before saving.

    Enforces:
      - Max 20 exercises per workout
      - Max 10 sets per exercise
      - Max 120 minutes total duration
      - No banned / nonsensical exercises
    """

    MAX_EXERCISES = 20
    MAX_SETS_PER_EXERCISE = 10
    MAX_DURATION_MINUTES = 120
    BANNED_TERMS = {"skull crusher on bosu ball", "behind the neck press to failure"}

    @classmethod
    def validate(cls, workout: dict) -> list[str]:
        """Return a list of violation strings. Empty list = safe."""
        violations: list[str] = []

        exercises = workout.get("exercises", [])
        if len(exercises) > cls.MAX_EXERCISES:
            violations.append(
                f"Too many exercises: {len(exercises)} (max {cls.MAX_EXERCISES})"
            )

        duration = workout.get("estimatedDuration") or workout.get("durationMinutes", 0)
        if duration > cls.MAX_DURATION_MINUTES:
            violations.append(
                f"Duration too long: {duration}min (max {cls.MAX_DURATION_MINUTES})"
            )

        for idx, ex in enumerate(exercises):
            sets = ex.get("sets", 1)
            if sets > cls.MAX_SETS_PER_EXERCISE:
                violations.append(
                    f"Exercise #{idx + 1} ({ex.get('name', '?')}): "
                    f"{sets} sets exceeds max {cls.MAX_SETS_PER_EXERCISE}"
                )

            name = (ex.get("name") or "").lower()
            for banned in cls.BANNED_TERMS:
                if banned in name:
                    violations.append(
                        f"Exercise #{idx + 1}: banned exercise '{name}'"
                    )

        return violations
