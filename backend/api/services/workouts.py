import uuid
from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from database.models import FitnessLevel, WorkoutLog, WorkoutPlan
from infrastructure.repositories.sqlalchemy_workoutlog_repository import (
    SQLAlchemyWorkoutLogRepository,
)
from infrastructure.repositories.sqlalchemy_workoutplan_repository import (
    SQLAlchemyWorkoutPlanRepository,
)


async def create_workout_plan(
    db: Session, user_id: str, plan_data: dict
) -> WorkoutPlan:
    """Create a new workout plan."""
    repo = SQLAlchemyWorkoutPlanRepository(db)
    plan = WorkoutPlan(
        id=str(uuid.uuid4()),
        user_id=user_id,
        name=plan_data["name"],
        description=plan_data["description"],
        exercises=[exercise.dict() for exercise in plan_data["exercises"]],
        duration_minutes=plan_data["duration_minutes"],
        difficulty=FitnessLevel.INTERMEDIATE,
        equipment_needed=plan_data.get("equipment_needed", []),
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    return await repo.add(plan)


async def get_user_workout_plans(
    db: Session, user_id: str, limit: int = 50
) -> list[WorkoutPlan]:
    """Get user's workout plans."""
    repo = SQLAlchemyWorkoutPlanRepository(db)
    return await repo.list(user_id=user_id, limit=limit)


async def get_workout_plan(db: Session, plan_id: str, user_id: str) -> WorkoutPlan:
    """Get a specific workout plan."""
    repo = SQLAlchemyWorkoutPlanRepository(db)
    plan = await repo.get(plan_id)
    if plan is None or plan.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Workout plan not found"
        )
    return plan


async def log_workout(db: Session, user_id: str, log_data: dict) -> WorkoutLog:
    """Log a completed workout."""
    # Verify workout plan exists via repository
    plan_repo = SQLAlchemyWorkoutPlanRepository(db)
    plan = await plan_repo.get(log_data["plan_id"])
    if plan is None or plan.user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Workout plan not found"
        )

    log_repo = SQLAlchemyWorkoutLogRepository(db)
    log = WorkoutLog(
        id=str(uuid.uuid4()),
        user_id=user_id,
        plan_id=log_data["plan_id"],
        completed_at=datetime.utcnow(),
        duration_minutes=log_data["duration_minutes"],
        exercises=[exercise.dict() for exercise in log_data["exercises"]],
        notes=log_data.get("notes"),
        rating=log_data.get("rating"),
        created_at=datetime.utcnow(),
    )
    return await log_repo.add(log)


async def get_user_workout_logs(
    db: Session, user_id: str, limit: int = 50
) -> list[WorkoutLog]:
    """Get user's workout logs."""
    repo = SQLAlchemyWorkoutLogRepository(db)
    return await repo.list(user_id=user_id, limit=limit)


async def get_user_workout_days(db: Session, user_id: str) -> list[str]:
    """Return list of ISO date strings (YYYY-MM-DD) when user completed workouts."""
    repo = SQLAlchemyWorkoutLogRepository(db)
    return await repo.list_dates(user_id)
