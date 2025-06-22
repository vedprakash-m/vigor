import uuid
from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from database.models import ProgressMetrics, UserProfile
from infrastructure.repositories.sqlalchemy_progress_repository import (
    SQLAlchemyProgressRepository,
)
from infrastructure.repositories.sqlalchemy_user_repository import (
    SQLAlchemyUserRepository,
)


async def get_user_profile(db: Session, user_id: str) -> UserProfile:
    """Get user profile by ID."""
    repo = SQLAlchemyUserRepository(db)
    user = await repo.get(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    return user


async def update_user_profile(
    db: Session, user_id: str, update_data: dict
) -> UserProfile:
    """Update user profile."""
    repo = SQLAlchemyUserRepository(db)
    try:
        return await repo.update(user_id, update_data)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )


async def create_progress_metric(
    db: Session, user_id: str, metric_data: dict
) -> ProgressMetrics:
    """Create a new progress metric entry."""
    repo = SQLAlchemyProgressRepository(db)
    metric = ProgressMetrics(
        id=str(uuid.uuid4()),
        user_id=user_id,
        date=datetime.utcnow(),
        weight=metric_data.get("weight"),
        body_fat=metric_data.get("body_fat"),
        measurements=metric_data.get("measurements"),
        notes=metric_data.get("notes"),
        created_at=datetime.utcnow(),
    )
    return await repo.add(metric)


async def get_user_progress(
    db: Session, user_id: str, limit: int = 50
) -> list[ProgressMetrics]:
    """Get user progress metrics."""
    repo = SQLAlchemyProgressRepository(db)
    return await repo.list(user_id=user_id, limit=limit)


class UserService:
    """User service class for handling user-related operations."""

    def __init__(self, db: Session):
        self.db = db

    async def get_profile(self, user_id: str) -> UserProfile:
        """Get user profile."""
        return await get_user_profile(self.db, user_id)

    async def update_profile(self, user_id: str, update_data: dict) -> UserProfile:
        """Update user profile."""
        return await update_user_profile(self.db, user_id, update_data)

    async def create_progress_metric(
        self, user_id: str, metric_data: dict
    ) -> ProgressMetrics:
        """Create progress metric."""
        return await create_progress_metric(self.db, user_id, metric_data)

    async def get_progress(
        self, user_id: str, limit: int = 50
    ) -> list[ProgressMetrics]:
        """Get user progress."""
        return await get_user_progress(self.db, user_id, limit)


# Alias for tests that expect UsersService
UsersService = UserService
