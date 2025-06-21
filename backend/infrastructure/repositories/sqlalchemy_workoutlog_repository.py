from __future__ import annotations

from datetime import datetime

from sqlalchemy import desc
from sqlalchemy.orm import Session
from typing import Optional, List

from database.models import WorkoutLog
from database.sql_models import WorkoutLogDB
from domain.repositories.base import BaseRepository


class SQLAlchemyWorkoutLogRepository(BaseRepository[WorkoutLog]):
    """Repository wrapping CRUD operations for ``WorkoutLog`` using SQLAlchemy."""

    def __init__(self, session: Session):
        self.session = session

    async def get(self, entity_id: str) -> Optional[WorkoutLog]:
        record = (
            self.session.query(WorkoutLogDB)
            .filter(WorkoutLogDB.id == entity_id)
            .first()
        )
        return None if record is None else WorkoutLog.model_validate(record)

    async def create(self, entity: WorkoutLog) -> WorkoutLog:
        db_obj = WorkoutLogDB(**entity.model_dump())
        self.session.add(db_obj)
        self.session.commit()
        self.session.refresh(db_obj)
        return WorkoutLog.model_validate(db_obj)

    async def update(self, entity: WorkoutLog) -> WorkoutLog:
        record = (
            self.session.query(WorkoutLogDB)
            .filter(WorkoutLogDB.id == entity.id)
            .first()
        )
        if record is None:
            raise ValueError("WorkoutLog not found")

        for field, value in entity.model_dump().items():
            if value is not None:
                setattr(record, field, value)

        self.session.commit()
        self.session.refresh(record)
        return WorkoutLog.model_validate(record)

    async def delete(self, entity_id: str) -> bool:
        record = (
            self.session.query(WorkoutLogDB)
            .filter(WorkoutLogDB.id == entity_id)
            .first()
        )
        if record is None:
            return False

        self.session.delete(record)
        self.session.commit()
        return True

    async def list(self, limit: int = 100, offset: int = 0) -> List[WorkoutLog]:
        query = self.session.query(WorkoutLogDB)
        records = query.offset(offset).limit(limit).all()
        return [WorkoutLog.model_validate(r) for r in records]

    async def list_dates(self, user_id: str) -> list[str]:
        rows = (
            self.session.query(WorkoutLogDB.completed_at)
            .filter(WorkoutLogDB.user_id == user_id)
            .order_by(desc(WorkoutLogDB.completed_at))
            .all()
        )
        return sorted(
            {dt.completed_at.date().isoformat() for dt in rows if dt.completed_at}
        )
