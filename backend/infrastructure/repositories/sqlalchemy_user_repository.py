from __future__ import annotations

from datetime import datetime

from sqlalchemy.orm import Session

from database.models import UserProfile
from database.sql_models import UserProfileDB
from domain.repositories.base import Repository


class SQLAlchemyUserRepository(Repository[UserProfile]):
    """Repository wrapping CRUD operations for ``UserProfile`` using SQLAlchemy."""

    def __init__(self, session: Session):  # noqa: D401
        self._session = session

    async def get(self, entity_id: str) -> UserProfile | None:
        record = (
            self._session.query(UserProfileDB)
            .filter(UserProfileDB.id == entity_id)
            .first()
        )
        return None if record is None else UserProfile.model_validate(record)

    async def add(self, entity: UserProfile) -> UserProfile:
        db_obj = UserProfileDB(**entity.model_dump())  # type: ignore[arg-type]
        self._session.add(db_obj)
        self._session.commit()
        self._session.refresh(db_obj)
        return UserProfile.model_validate(db_obj)

    async def update(self, entity_id: str, update_data: dict) -> UserProfile:
        record = (
            self._session.query(UserProfileDB)
            .filter(UserProfileDB.id == entity_id)
            .first()
        )
        if record is None:
            raise ValueError("User not found")

        for field, value in update_data.items():
            if value is not None:
                setattr(record, field, value)
        record.updated_at = datetime.utcnow()
        self._session.commit()
        self._session.refresh(record)
        return UserProfile.model_validate(record)

    async def list(self, **filters) -> list[UserProfile]:
        query = self._session.query(UserProfileDB)
        for field, value in filters.items():
            if hasattr(UserProfileDB, field):
                query = query.filter(getattr(UserProfileDB, field) == value)
        records = query.all()
        return [UserProfile.model_validate(r) for r in records]
