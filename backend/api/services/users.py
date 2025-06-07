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

    return UserProfile.model_validate(user)


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

    user.updated_at = datetime.utcnow()  # type: ignore[assignment]
    db.commit()
    db.refresh(user)

    return UserProfile.model_validate(user)


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

    return ProgressMetrics.model_validate(db_metric)


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
        ProgressMetrics.model_validate(metric) for metric in metrics
    ]
