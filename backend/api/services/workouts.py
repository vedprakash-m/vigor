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

    return WorkoutPlan(
        id=db_plan.id,
        user_id=db_plan.user_id,
        name=db_plan.name,
        description=db_plan.description,
        exercises=db_plan.exercises,
        duration_minutes=db_plan.duration_minutes,
        difficulty=db_plan.difficulty,
        equipment_needed=db_plan.equipment_needed,
        created_at=db_plan.created_at,
        updated_at=db_plan.updated_at,
    )


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

    return [
        WorkoutPlan(
            id=plan.id,
            user_id=plan.user_id,
            name=plan.name,
            description=plan.description,
            exercises=plan.exercises,
            duration_minutes=plan.duration_minutes,
            difficulty=plan.difficulty,
            equipment_needed=plan.equipment_needed,
            created_at=plan.created_at,
            updated_at=plan.updated_at,
        )
        for plan in plans
    ]


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

    return WorkoutPlan(
        id=plan.id,
        user_id=plan.user_id,
        name=plan.name,
        description=plan.description,
        exercises=plan.exercises,
        duration_minutes=plan.duration_minutes,
        difficulty=plan.difficulty,
        equipment_needed=plan.equipment_needed,
        created_at=plan.created_at,
        updated_at=plan.updated_at,
    )


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

    return WorkoutLog(
        id=db_log.id,
        user_id=db_log.user_id,
        plan_id=db_log.plan_id,
        completed_at=db_log.completed_at,
        duration_minutes=db_log.duration_minutes,
        exercises=db_log.exercises,
        notes=db_log.notes,
        rating=db_log.rating,
        created_at=db_log.created_at,
    )


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

    return [
        WorkoutLog(
            id=log.id,
            user_id=log.user_id,
            plan_id=log.plan_id,
            completed_at=log.completed_at,
            duration_minutes=log.duration_minutes,
            exercises=log.exercises,
            notes=log.notes,
            rating=log.rating,
            created_at=log.created_at,
        )
        for log in logs
    ]
