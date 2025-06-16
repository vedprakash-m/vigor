from __future__ import annotations

import uuid
from datetime import datetime
from typing import List, Optional

from sqlalchemy import desc
from sqlalchemy.orm import Session

from database.models import FitnessLevel, WorkoutPlan
from database.sql_models import WorkoutPlanDB
from domain.repositories.base import Repository


class SQLAlchemyWorkoutPlanRepository(Repository[WorkoutPlan]):
    def __init__(self, session: Session):
        self._session = session

    async def get(self, entity_id: str) -> Optional[WorkoutPlan]:
        record = (
            self._session.query(WorkoutPlanDB)
            .filter(WorkoutPlanDB.id == entity_id)
            .first()
        )
        return None if record is None else WorkoutPlan.model_validate(record)

    async def add(self, entity: WorkoutPlan) -> WorkoutPlan:
        db_obj = WorkoutPlanDB(**entity.model_dump())  # type: ignore[arg-type]
        self._session.add(db_obj)
        self._session.commit()
        self._session.refresh(db_obj)
        return WorkoutPlan.model_validate(db_obj)

    async def update(self, entity_id: str, update_data: dict) -> WorkoutPlan:
        rec = (
            self._session.query(WorkoutPlanDB)
            .filter(WorkoutPlanDB.id == entity_id)
            .first()
        )
        if rec is None:
            raise ValueError("Workout plan not found")
        for k, v in update_data.items():
            if v is not None:
                setattr(rec, k, v)
        rec.updated_at = datetime.utcnow()
        self._session.commit()
        self._session.refresh(rec)
        return WorkoutPlan.model_validate(rec)

    async def list(self, **filters) -> List[WorkoutPlan]:
        user_id = filters.get("user_id")
        limit = filters.get("limit", 50)
        q = self._session.query(WorkoutPlanDB)
        if user_id:
            q = q.filter(WorkoutPlanDB.user_id == user_id)
        records = q.order_by(desc(WorkoutPlanDB.created_at)).limit(limit).all()
        return [WorkoutPlan.model_validate(r) for r in records]
