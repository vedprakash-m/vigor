import uuid
from datetime import datetime
from typing import List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from database.models import ProgressMetrics, UserProfile
from database.sql_models import ProgressMetricsDB, UserProfileDB


async def get_user_profile(db: Session, user_id: str) -> UserProfile:
    """Get user profile by ID."""
    user = db.query(UserProfileDB).filter(UserProfileDB.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    return UserProfile(
        id=user.id,
        email=user.email,
        username=user.username,
        fitness_level=user.fitness_level,
        goals=user.goals or [],
        equipment=user.equipment,
        injuries=user.injuries or [],
        preferences=user.preferences or {},
        created_at=user.created_at,
        updated_at=user.updated_at,
    )


async def update_user_profile(
    db: Session, user_id: str, update_data: dict
) -> UserProfile:
    """Update user profile."""
    user = db.query(UserProfileDB).filter(UserProfileDB.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    # Update only provided fields
    for field, value in update_data.items():
        if value is not None:
            setattr(user, field, value)

    user.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(user)

    return UserProfile(
        id=user.id,
        email=user.email,
        username=user.username,
        fitness_level=user.fitness_level,
        goals=user.goals or [],
        equipment=user.equipment,
        injuries=user.injuries or [],
        preferences=user.preferences or {},
        created_at=user.created_at,
        updated_at=user.updated_at,
    )


async def create_progress_metric(
    db: Session, user_id: str, metric_data: dict
) -> ProgressMetrics:
    """Create a new progress metric entry."""
    db_metric = ProgressMetricsDB(
        id=str(uuid.uuid4()),
        user_id=user_id,
        date=datetime.utcnow(),
        weight=metric_data.get("weight"),
        body_fat=metric_data.get("body_fat"),
        measurements=metric_data.get("measurements"),
        notes=metric_data.get("notes"),
    )

    db.add(db_metric)
    db.commit()
    db.refresh(db_metric)

    return ProgressMetrics(
        id=db_metric.id,
        user_id=db_metric.user_id,
        date=db_metric.date,
        weight=db_metric.weight,
        body_fat=db_metric.body_fat,
        measurements=db_metric.measurements,
        notes=db_metric.notes,
        created_at=db_metric.created_at,
    )


async def get_user_progress(
    db: Session, user_id: str, limit: int = 50
) -> List[ProgressMetrics]:
    """Get user progress metrics."""
    metrics = (
        db.query(ProgressMetricsDB)
        .filter(ProgressMetricsDB.user_id == user_id)
        .order_by(ProgressMetricsDB.date.desc())
        .limit(limit)
        .all()
    )

    return [
        ProgressMetrics(
            id=metric.id,
            user_id=metric.user_id,
            date=metric.date,
            weight=metric.weight,
            body_fat=metric.body_fat,
            measurements=metric.measurements,
            notes=metric.notes,
            created_at=metric.created_at,
        )
        for metric in metrics
    ]
