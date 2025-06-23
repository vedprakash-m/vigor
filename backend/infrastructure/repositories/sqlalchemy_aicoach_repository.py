from __future__ import annotations

from sqlalchemy.orm import Session

from database.models import AICoachMessage
from database.sql_models import AICoachMessageDB
from domain.repositories.base import BaseRepository as Repository


class SQLAlchemyAICoachMessageRepository(Repository[AICoachMessage]):
    """Repository wrapping CRUD operations for ``AICoachMessage`` using SQLAlchemy."""

    def __init__(self, session: Session):
        self.session = session

    async def get(self, entity_id: str) -> Optional[AICoachMessage]:
        record = (
            self.session.query(AICoachMessageDB)
            .filter(AICoachMessageDB.id == entity_id)
            .first()
        )
        return None if record is None else AICoachMessage.model_validate(record)

    async def create(self, entity: AICoachMessage) -> AICoachMessage:
        db_obj = AICoachMessageDB(**entity.model_dump())
        self.session.add(db_obj)
        self.session.commit()
        self.session.refresh(db_obj)
        return AICoachMessage.model_validate(db_obj)

    async def update(self, entity: AICoachMessage) -> AICoachMessage:
        record = (
            self.session.query(AICoachMessageDB)
            .filter(AICoachMessageDB.id == entity.id)
            .first()
        )
        if record is None:
            raise ValueError("AICoachMessage not found")

        for field, value in entity.model_dump().items():
            if value is not None:
                setattr(record, field, value)

        self.session.commit()
        self.session.refresh(record)
        return AICoachMessage.model_validate(record)

    async def delete(self, entity_id: str) -> bool:
        record = (
            self.session.query(AICoachMessageDB)
            .filter(AICoachMessageDB.id == entity_id)
            .first()
        )
        if record is None:
            return False

        self.session.delete(record)
        self.session.commit()
        return True

    async def list(self, limit: int = 100, offset: int = 0) -> List[AICoachMessage]:
        query = self.session.query(AICoachMessageDB)
        records = query.offset(offset).limit(limit).all()
        return [AICoachMessage.model_validate(r) for r in records]
