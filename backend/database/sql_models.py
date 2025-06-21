import uuid

from sqlalchemy import (
    JSON,
    Boolean,
    Column,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy import Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from .connection import Base
from .models import Equipment, FitnessLevel


class UserProfileDB(Base):
    __tablename__ = "user_profiles"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    last_login = Column(DateTime, nullable=True)
    fitness_level: Column[FitnessLevel] = Column(SQLEnum(FitnessLevel))
    goals = Column(JSON)  # Store as JSON array
    equipment: Column[Equipment] = Column(SQLEnum(Equipment))
    injuries = Column(JSON, default=list)  # Store as JSON array
    preferences = Column(JSON, default=dict)
    user_tier = Column(String, default="free")
    tier_updated_at = Column(DateTime, nullable=True)
    monthly_budget = Column(Float, default=5.0)
    current_month_usage = Column(Float, default=0.0)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    workout_plans = relationship("WorkoutPlanDB", back_populates="user")
    workout_logs = relationship("WorkoutLogDB", back_populates="user")
    progress_metrics = relationship("ProgressMetricsDB", back_populates="user")
    ai_messages = relationship("AICoachMessageDB", back_populates="user")
    usage_limits = relationship("UserUsageLimitsDB", back_populates="user")


class WorkoutPlanDB(Base):
    __tablename__ = "workout_plans"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("user_profiles.id"))
    name = Column(String)
    description = Column(Text)
    exercises = Column(JSON)  # Store as JSON array
    duration_minutes = Column(Integer)
    difficulty: Column[FitnessLevel] = Column(SQLEnum(FitnessLevel))
    equipment_needed = Column(JSON)  # Store as JSON array
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("UserProfileDB", back_populates="workout_plans")
    workout_logs = relationship("WorkoutLogDB", back_populates="plan")


class WorkoutLogDB(Base):
    __tablename__ = "workout_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("user_profiles.id"))
    plan_id = Column(String, ForeignKey("workout_plans.id"))
    completed_at = Column(DateTime, default=func.now())
    duration_minutes = Column(Integer)
    exercises = Column(JSON)  # Store as JSON array
    notes = Column(Text)
    rating = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=func.now())

    # Relationships
    user = relationship("UserProfileDB", back_populates="workout_logs")
    plan = relationship("WorkoutPlanDB", back_populates="workout_logs")


class ProgressMetricsDB(Base):
    __tablename__ = "progress_metrics"

    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("user_profiles.id"))
    date = Column(DateTime)
    weight = Column(Float, nullable=True)
    body_fat = Column(Float, nullable=True)
    measurements = Column(JSON, nullable=True)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=func.now())

    # Relationships
    user = relationship("UserProfileDB", back_populates="progress_metrics")


class AICoachMessageDB(Base):
    __tablename__ = "ai_coach_messages"

    id = Column(String, primary_key=True)
    user_id = Column(String, ForeignKey("user_profiles.id"))
    message = Column(String)
    response = Column(String)
    context = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=func.now())

    # Relationships
    user = relationship("UserProfileDB", back_populates="ai_messages")


class ChatMessageDB(Base):
    __tablename__ = "chat_messages"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, index=True)
    message = Column(Text)
    response = Column(Text)
    created_at = Column(DateTime, default=func.now())


class AIProviderPriorityDB(Base):
    __tablename__ = "ai_provider_priorities"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    provider_name = Column(String, index=True)
    model_name = Column(String)
    priority = Column(Integer, index=True)
    is_enabled = Column(Boolean, default=True, index=True)
    max_daily_cost = Column(Float)
    max_weekly_cost = Column(Float)
    max_monthly_cost = Column(Float)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    __table_args__ = (Index("idx_provider_priority", "priority", "is_enabled"),)


class BudgetSettingsDB(Base):
    __tablename__ = "budget_settings"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    total_weekly_budget = Column(Float)
    total_monthly_budget = Column(Float)
    alert_threshold_percentage = Column(Float, default=80.0)
    auto_disable_on_budget_exceeded = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())


class AIUsageLogDB(Base):
    __tablename__ = "ai_usage_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    provider_name = Column(String, index=True)
    model_name = Column(String, index=True)
    user_id = Column(String, index=True)
    endpoint = Column(String, index=True)
    input_tokens = Column(Integer)
    output_tokens = Column(Integer)
    cost = Column(Float, index=True)
    response_time_ms = Column(Integer)
    success = Column(Boolean, index=True)
    error_message = Column(Text)
    created_at = Column(DateTime, default=func.now(), index=True)

    __table_args__ = (
        Index("idx_usage_date_provider", "created_at", "provider_name"),
        Index("idx_usage_cost_tracking", "created_at", "cost", "provider_name"),
    )


class AdminSettingsDB(Base):
    __tablename__ = "admin_settings"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    key = Column(String, unique=True, index=True)
    value = Column(Text)
    description = Column(Text)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())


class UserUsageLimitsDB(Base):
    __tablename__ = "user_usage_limits"

    id = Column(Integer, primary_key=True)
    user_id = Column(String, ForeignKey("user_profiles.id"))
    daily_requests_used = Column(Integer, default=0)
    weekly_requests_used = Column(Integer, default=0)
    monthly_requests_used = Column(Integer, default=0)
    last_reset_date = Column(Date, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("UserProfileDB", back_populates="usage_limits")


class UserTierLimitsDB(Base):
    __tablename__ = "user_tier_limits"

    id = Column(Integer, primary_key=True)
    tier_name = Column(String, unique=True)
    daily_limit = Column(Integer)
    weekly_limit = Column(Integer)
    monthly_limit = Column(Integer)
    monthly_budget = Column(Float)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
