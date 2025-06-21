from __future__ import annotations

from sqlalchemy import desc
from sqlalchemy.orm import Session
from typing import Optional, List

from database.models import ProgressMetrics
from database.sql_models import ProgressMetricsDB
from domain.repositories.base import BaseRepository as Repository


class SQLAlchemyProgressRepository(Repository[ProgressMetrics]):
    """CRUD operations for ProgressMetrics using SQLAlchemy."""

    def __init__(self, session: Session):
        self._session = session

    async def get(self, entity_id: str) -> Optional[ProgressMetrics]:
        record = (
            self._session.query(ProgressMetricsDB)
            .filter(ProgressMetricsDB.id == entity_id)
            .first()
        )
        return None if record is None else ProgressMetrics.model_validate(record)

    async def create(self, entity: ProgressMetrics) -> ProgressMetrics:
        db_obj = ProgressMetricsDB(**entity.model_dump())  # type: ignore[arg-type]
        self._session.add(db_obj)
        self._session.commit()
        self._session.refresh(db_obj)
        return ProgressMetrics.model_validate(db_obj)

    async def update(self, entity: ProgressMetrics) -> ProgressMetrics:
        record = (
            self._session.query(ProgressMetricsDB)
            .filter(ProgressMetricsDB.id == entity.id)
            .first()
        )
        if record is None:
            raise ValueError("Progress metric not found")
        for k, v in entity.model_dump().items():
            if v is not None:
                setattr(record, k, v)
        self._session.commit()
        self._session.refresh(record)
        return ProgressMetrics.model_validate(record)

    async def delete(self, entity_id: str) -> bool:
        record = (
            self._session.query(ProgressMetricsDB)
            .filter(ProgressMetricsDB.id == entity_id)
            .first()
        )
        if record is None:
            return False

        self._session.delete(record)
        self._session.commit()
        return True

    async def list(self, limit: int = 100, offset: int = 0) -> List[ProgressMetrics]:
        query = self._session.query(ProgressMetricsDB).order_by(desc(ProgressMetricsDB.date))
        records = query.offset(offset).limit(limit).all()
        return [ProgressMetrics.model_validate(r) for r in records]

    # Alias for backward compatibility
    async def add(self, entity: ProgressMetrics) -> ProgressMetrics:
        """Alias for create method."""
        return await self.create(entity)
