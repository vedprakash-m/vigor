from __future__ import annotations

from sqlalchemy import desc
from sqlalchemy.orm import Session

from database.models import AICoachMessage
from database.sql_models import AICoachMessageDB
from domain.repositories.base import BaseRepository as Repository


class SQLAlchemyAICoachMessageRepository(Repository[AICoachMessage]):
    def __init__(self, session: Session):
        self._session = session

    async def get(self, entity_id: str) -> AICoachMessage] = None:
        rec = (
            self._session.query(AICoachMessageDB)
            .filter(AICoachMessageDB.id == entity_id)
            .first()
        )
        return None if rec is None else AICoachMessage.model_validate(rec)

    async def add(self, entity: AICoachMessage) -> AICoachMessage:
        db_obj = AICoachMessageDB(**entity.model_dump())  # type: ignore[arg-type]
        self._session.add(db_obj)
        self._session.commit()
        self._session.refresh(db_obj)
        return AICoachMessage.model_validate(db_obj)

    async def update(self, entity_id: str, update_data: dict) -> AICoachMessage:
        rec = (
            self._session.query(AICoachMessageDB)
            .filter(AICoachMessageDB.id == entity_id)
            .first()
        )
        if rec is None:
            raise ValueError("Coach message not found")
        for k, v in update_data.items():
            if v is not None:
                setattr(rec, k, v)
        self._session.commit()
        self._session.refresh(rec)
        return AICoachMessage.model_validate(rec)

    async def list(self, **filters) -> list[AICoachMessage]:
        user_id = filters.get("user_id")
        limit = filters.get("limit", 20)
        q = self._session.query(AICoachMessageDB)
        if user_id:
            q = q.filter(AICoachMessageDB.user_id == user_id)
        q = q.order_by(desc(AICoachMessageDB.created_at)).limit(limit)
        return [AICoachMessage.model_validate(r) for r in q.all()]
