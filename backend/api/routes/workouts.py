from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from api.schemas.workouts import (
    WorkoutLogCreate,
    WorkoutLogResponse,
    WorkoutPlanCreate,
    WorkoutPlanResponse,
)
from api.services.workouts import (
    create_workout_plan,
    get_user_workout_days,
    get_user_workout_logs,
    get_user_workout_plans,
    get_workout_plan,
    log_workout,
)
from core.security import get_current_active_user
from database.connection import get_db
from database.models import UserProfile

router = APIRouter(prefix="/workouts", tags=["workouts"])


@router.get("/plans", response_model=list[WorkoutPlanResponse])
async def list_plans(
    limit: int = 50,
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """List user's workout plans."""
    return await get_user_workout_plans(db, current_user.id, limit)


@router.post("/plans", response_model=WorkoutPlanResponse)
async def create_plan(
    plan_data: WorkoutPlanCreate,
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Create a new workout plan."""
    return await create_workout_plan(db, current_user.id, plan_data.dict())


@router.get("/plans/{plan_id}", response_model=WorkoutPlanResponse)
async def get_plan(
    plan_id: str,
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Get workout plan details."""
    return await get_workout_plan(db, plan_id, current_user.id)


@router.post("/logs", response_model=WorkoutLogResponse)
async def log_workout_session(
    log_data: WorkoutLogCreate,
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Log a completed workout session."""
    return await log_workout(db, current_user.id, log_data.dict())


@router.get("/logs", response_model=list[WorkoutLogResponse])
async def get_logs(
    limit: int = 50,
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Get user's workout history."""
    return await get_user_workout_logs(db, current_user.id, limit)


@router.get("/days", response_model=list[str])
async def get_workout_days(
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Return list of days with completed workouts for streak calculation."""
    return await get_user_workout_days(db, current_user.id)
