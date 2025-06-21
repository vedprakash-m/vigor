from __future__ import annotations

from sqlalchemy import desc
from sqlalchemy.orm import Session

from database.models import ProgressMetrics
from database.sql_models import ProgressMetricsDB
from domain.repositories.base import Repository


class SQLAlchemyProgressRepository(Repository[ProgressMetrics]):
    """CRUD operations for ProgressMetrics using SQLAlchemy."""

    def __init__(self, session: Session):
        self._session = session

    async def get(self, entity_id: str):  # noqa: D401
        record = (
            self._session.query(ProgressMetricsDB)
            .filter(ProgressMetricsDB.id == entity_id)
            .first()
        )
        return None if record is None else ProgressMetrics.model_validate(record)

    async def add(self, entity: ProgressMetrics):
        db_obj = ProgressMetricsDB(**entity.model_dump())  # type: ignore[arg-type]
        self._session.add(db_obj)
        self._session.commit()
        self._session.refresh(db_obj)
        return ProgressMetrics.model_validate(db_obj)

    async def update(self, entity_id: str, update_data: dict):
        record = (
            self._session.query(ProgressMetricsDB)
            .filter(ProgressMetricsDB.id == entity_id)
            .first()
        )
        if record is None:
            raise ValueError("Progress metric not found")
        for k, v in update_data.items():
            if v is not None:
                setattr(record, k, v)
        self._session.commit()
        self._session.refresh(record)
        return ProgressMetrics.model_validate(record)

    async def list(self, **filters) -> list[ProgressMetrics]:
        user_id = filters.get("user_id")
        limit = filters.get("limit", 50)
        query = self._session.query(ProgressMetricsDB)
        if user_id:
            query = query.filter(ProgressMetricsDB.user_id == user_id)
        records = query.order_by(desc(ProgressMetricsDB.date)).limit(limit).all()
        return [ProgressMetrics.model_validate(r) for r in records]
