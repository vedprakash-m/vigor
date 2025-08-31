from __future__ import annotations

from sqlalchemy.orm import Session

from database.models import WorkoutPlan
from database.sql_models import WorkoutPlanDB
from domain.repositories.base import BaseRepository as Repository


class SQLAlchemyWorkoutPlanRepository(Repository[WorkoutPlan]):
    """Repository wrapping CRUD operations for ``WorkoutPlan`` using SQLAlchemy."""

    def __init__(self, session: Session):
        self.session = session

    async def get(self, entity_id: str) -> WorkoutPlan | None:
        record = (
            self.session.query(WorkoutPlanDB)
            .filter(WorkoutPlanDB.id == entity_id)
            .first()
        )
        return None if record is None else WorkoutPlan.model_validate(record)

    async def create(self, entity: WorkoutPlan) -> WorkoutPlan:
        db_obj = WorkoutPlanDB(**entity.model_dump())
        self.session.add(db_obj)
        self.session.commit()
        self.session.refresh(db_obj)
        return WorkoutPlan.model_validate(db_obj)

    async def update(self, entity: WorkoutPlan) -> WorkoutPlan:
        record = (
            self.session.query(WorkoutPlanDB)
            .filter(WorkoutPlanDB.id == entity.id)
            .first()
        )
        if record is None:
            raise ValueError("WorkoutPlan not found")

        for field, value in entity.model_dump().items():
            if value is not None:
                setattr(record, field, value)

        self.session.commit()
        self.session.refresh(record)
        return WorkoutPlan.model_validate(record)

    async def delete(self, entity_id: str) -> bool:
        record = (
            self.session.query(WorkoutPlanDB)
            .filter(WorkoutPlanDB.id == entity_id)
            .first()
        )
        if record is None:
            return False

        self.session.delete(record)
        self.session.commit()
        return True

    async def list(self, limit: int = 100, offset: int = 0) -> list[WorkoutPlan]:
        query = self.session.query(WorkoutPlanDB)
        records = query.offset(offset).limit(limit).all()
        return [WorkoutPlan.model_validate(r) for r in records]
