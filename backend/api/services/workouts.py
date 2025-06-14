import uuid
from datetime import datetime
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from database.models import FitnessLevel, UserProfile, WorkoutLog, WorkoutPlan
from database.sql_models import WorkoutLogDB, WorkoutPlanDB


async def create_workout_plan(
    db: Session, user_id: str, plan_data: dict
) -> WorkoutPlan:
    """Create a new workout plan."""
    db_plan = WorkoutPlanDB(
        id=str(uuid.uuid4()),
        user_id=user_id,
        name=plan_data["name"],
        description=plan_data["description"],
        exercises=[exercise.dict() for exercise in plan_data["exercises"]],
        duration_minutes=plan_data["duration_minutes"],
        difficulty=FitnessLevel.INTERMEDIATE,  # Default, can be determined by AI later
        equipment_needed=plan_data.get("equipment_needed", []),
    )

    db.add(db_plan)
    db.commit()
    db.refresh(db_plan)

    return WorkoutPlan.model_validate(db_plan)


async def get_user_workout_plans(
    db: Session, user_id: str, limit: int = 50
) -> List[WorkoutPlan]:
    """Get user's workout plans."""
    plans = (
        db.query(WorkoutPlanDB)
        .filter(WorkoutPlanDB.user_id == user_id)
        .order_by(WorkoutPlanDB.created_at.desc())
        .limit(limit)
        .all()
    )

    return [WorkoutPlan.model_validate(plan) for plan in plans]


async def get_workout_plan(db: Session, plan_id: str, user_id: str) -> WorkoutPlan:
    """Get a specific workout plan."""
    plan = (
        db.query(WorkoutPlanDB)
        .filter(WorkoutPlanDB.id == plan_id, WorkoutPlanDB.user_id == user_id)
        .first()
    )

    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Workout plan not found"
        )

    return WorkoutPlan.model_validate(plan)


async def log_workout(db: Session, user_id: str, log_data: dict) -> WorkoutLog:
    """Log a completed workout."""
    # Verify the workout plan exists and belongs to the user
    plan = (
        db.query(WorkoutPlanDB)
        .filter(
            WorkoutPlanDB.id == log_data["plan_id"], WorkoutPlanDB.user_id == user_id
        )
        .first()
    )

    if not plan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Workout plan not found"
        )

    db_log = WorkoutLogDB(
        id=str(uuid.uuid4()),
        user_id=user_id,
        plan_id=log_data["plan_id"],
        completed_at=datetime.utcnow(),
        duration_minutes=log_data["duration_minutes"],
        exercises=[exercise.dict() for exercise in log_data["exercises"]],
        notes=log_data.get("notes"),
        rating=log_data.get("rating"),
    )

    db.add(db_log)
    db.commit()
    db.refresh(db_log)

    return WorkoutLog.model_validate(db_log)


async def get_user_workout_logs(
    db: Session, user_id: str, limit: int = 50
) -> List[WorkoutLog]:
    """Get user's workout logs."""
    logs = (
        db.query(WorkoutLogDB)
        .filter(WorkoutLogDB.user_id == user_id)
        .order_by(WorkoutLogDB.completed_at.desc())
        .limit(limit)
        .all()
    )

    return [WorkoutLog.model_validate(log) for log in logs]


async def get_user_workout_days(db: Session, user_id: str) -> List[str]:
    """Return list of ISO date strings (YYYY-MM-DD) when user completed workouts."""
    rows = (
        db.query(WorkoutLogDB.completed_at)
        .filter(WorkoutLogDB.user_id == user_id)
        .order_by(WorkoutLogDB.completed_at.desc())
        .all()
    )
    dates = {
        dt.completed_at.date().isoformat()
        for dt in rows  # type: ignore
        if dt.completed_at is not None
    }
    return sorted(dates)
