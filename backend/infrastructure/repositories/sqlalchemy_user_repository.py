from __future__ import annotations

from datetime import datetime

from sqlalchemy.orm import Session

from database.models import UserProfile
from database.sql_models import UserProfileDB
from domain.repositories.base import BaseRepository as Repository
from typing import Optional, List


class SQLAlchemyUserRepository(Repository[UserProfile]):
    """Repository wrapping CRUD operations for ``UserProfile`` using SQLAlchemy."""

    def __init__(self, session: Session):  # noqa: D401
        self._session = session

    async def get(self, entity_id: str) -> Optional[UserProfile]:
        record = (
            self._session.query(UserProfileDB)
            .filter(UserProfileDB.id == entity_id)
            .first()
        )
        return None if record is None else UserProfile.model_validate(record)

    async def create(self, entity: UserProfile) -> UserProfile:
        db_obj = UserProfileDB(**entity.model_dump())  # type: ignore[arg-type]
        self._session.add(db_obj)
        self._session.commit()
        self._session.refresh(db_obj)
        return UserProfile.model_validate(db_obj)

    async def update(self, entity: UserProfile) -> UserProfile:
        record = (
            self._session.query(UserProfileDB)
            .filter(UserProfileDB.id == entity.id)
            .first()
        )
        if record is None:
            raise ValueError("User not found")

        for field, value in entity.model_dump().items():
            if value is not None:
                setattr(record, field, value)
        record.updated_at = datetime.utcnow()
        self._session.commit()
        self._session.refresh(record)
        return UserProfile.model_validate(record)

    async def delete(self, entity_id: str) -> bool:
        record = (
            self._session.query(UserProfileDB)
            .filter(UserProfileDB.id == entity_id)
            .first()
        )
        if record is None:
            return False

        self._session.delete(record)
        self._session.commit()
        return True

    async def list(self, limit: int = 100, offset: int = 0) -> List[UserProfile]:
        query = self._session.query(UserProfileDB).offset(offset).limit(limit)
        records = query.all()
        return [UserProfile.model_validate(r) for r in records]
