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
        # Get model data and handle field name mapping
        model_data = entity.model_dump()

        # Map metric_date (Pydantic) to date (SQLAlchemy)
        if 'metric_date' in model_data:
            model_data['date'] = model_data.pop('metric_date')

        # Remove fields that don't exist in SQLAlchemy model
        fields_to_remove = [
            'workouts_completed', 'total_workout_time_minutes', 'average_workout_rating',
            'current_streak_days', 'longest_streak_days', 'updated_at'
        ]
        for field in fields_to_remove:
            model_data.pop(field, None)

        db_obj = ProgressMetricsDB(**model_data)  # type: ignore[arg-type]
        self._session.add(db_obj)
        self._session.commit()
        self._session.refresh(db_obj)

        # Convert back to Pydantic with field name mapping
        db_dict = {
            'id': db_obj.id,
            'user_id': db_obj.user_id,
            'metric_date': db_obj.date.date() if hasattr(db_obj.date, 'date') else db_obj.date,  # Map date back to metric_date
            'weight': getattr(db_obj, 'weight', None),
            'body_fat': getattr(db_obj, 'body_fat', None),
            'measurements': getattr(db_obj, 'measurements', None),
            'notes': getattr(db_obj, 'notes', None),
            'created_at': db_obj.created_at,
        }

        return ProgressMetrics(**db_dict)

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

        # Convert each SQLAlchemy object to Pydantic with proper field handling
        result = []
        for record in records:
            db_dict = {
                'id': record.id,
                'user_id': record.user_id,
                'metric_date': record.date.date() if hasattr(record.date, 'date') else record.date,  # Map date to metric_date
                'weight': getattr(record, 'weight', None),
                'body_fat': getattr(record, 'body_fat', None),
                'measurements': getattr(record, 'measurements', None),
                'notes': getattr(record, 'notes', None),
                'created_at': record.created_at,
            }
            result.append(ProgressMetrics(**db_dict))

        return result

    # Alias for backward compatibility
    async def add(self, entity: ProgressMetrics) -> ProgressMetrics:
        """Alias for create method."""
        return await self.create(entity)
