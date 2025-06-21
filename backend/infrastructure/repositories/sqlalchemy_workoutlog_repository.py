from __future__ import annotations

from datetime import datetime

from sqlalchemy import desc
from sqlalchemy.orm import Session

from database.models import WorkoutLog
from database.sql_models import WorkoutLogDB
from domain.repositories.base import Repository


class SQLAlchemyWorkoutLogRepository(Repository[WorkoutLog]):
    def __init__(self, session: Session):
        self._session = session

    async def get(self, entity_id: str) -> WorkoutLog | None:  # noqa: D401
        rec = (
            self._session.query(WorkoutLogDB)
            .filter(WorkoutLogDB.id == entity_id)
            .first()
        )
        return None if rec is None else WorkoutLog.model_validate(rec)

    async def add(self, entity: WorkoutLog) -> WorkoutLog:
        db_obj = WorkoutLogDB(**entity.model_dump())  # type: ignore[arg-type]
        self._session.add(db_obj)
        self._session.commit()
        self._session.refresh(db_obj)
        return WorkoutLog.model_validate(db_obj)

    async def update(self, entity_id: str, update_data: dict) -> WorkoutLog:
        rec = (
            self._session.query(WorkoutLogDB)
            .filter(WorkoutLogDB.id == entity_id)
            .first()
        )
        if rec is None:
            raise ValueError("Workout log not found")
        for k, v in update_data.items():
            if v is not None:
                setattr(rec, k, v)
        rec.updated_at = datetime.utcnow()
        self._session.commit()
        self._session.refresh(rec)
        return WorkoutLog.model_validate(rec)

    async def list(self, **filters) -> list[WorkoutLog]:
        user_id = filters.get("user_id")
        limit = filters.get("limit", 50)
        q = self._session.query(WorkoutLogDB)
        if user_id:
            q = q.filter(WorkoutLogDB.user_id == user_id)
        q = q.order_by(desc(WorkoutLogDB.completed_at)).limit(limit)
        return [WorkoutLog.model_validate(r) for r in q.all()]

    async def list_dates(self, user_id: str) -> list[str]:
        rows = (
            self._session.query(WorkoutLogDB.completed_at)
            .filter(WorkoutLogDB.user_id == user_id)
            .order_by(desc(WorkoutLogDB.completed_at))
            .all()
        )
        return sorted(
            {dt.completed_at.date().isoformat() for dt in rows if dt.completed_at}
        )
