from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from api.schemas.users import (
    ProgressMetricCreate,
    ProgressMetricResponse,
    UserProfileResponse,
    UserProfileUpdate,
)
from api.services.users import (
    create_progress_metric,
    get_user_profile,
    get_user_progress,
    update_user_profile,
)
from core.security import get_current_active_user
from database.connection import get_db
from database.models import UserProfile

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserProfileResponse)
async def get_me(
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Get current user profile."""
    return current_user


@router.put("/me", response_model=UserProfileResponse)
async def update_me(
    profile_update: UserProfileUpdate,
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Update current user profile."""
    # Filter out None values
    update_data = {k: v for k, v in profile_update.dict().items() if v is not None}

    if not update_data:
        return current_user

    return await update_user_profile(db, current_user.id, update_data)


@router.post("/me/progress", response_model=ProgressMetricResponse)
async def add_progress_metric(
    metric: ProgressMetricCreate,
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Add a new progress metric."""
    return await create_progress_metric(db, current_user.id, metric.dict())


@router.get("/me/progress", response_model=List[ProgressMetricResponse])
async def get_my_progress(
    limit: int = 50,
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Get current user's progress metrics."""
    return await get_user_progress(db, current_user.id, limit)


@router.get("/{user_id}/progress", response_model=List[ProgressMetricResponse])
async def get_progress(
    user_id: str,
    limit: int = 50,
    current_user: UserProfile = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Get user progress metrics (admin or self only)."""
    # For now, only allow users to see their own progress
    if user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Access denied"
        )

    return await get_user_progress(db, user_id, limit)
