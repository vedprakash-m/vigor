from __future__ import annotations

from datetime import datetime

from sqlalchemy.orm import Session

from database.models import UserProfile
from database.sql_models import UserProfileDB
from domain.repositories.base import BaseRepository as Repository


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
        if record is None:
            return None

        # Convert SQLAlchemy object to dict for Pydantic validation
        db_dict = {
            "id": record.id,
            "email": record.email,
            "username": record.username,
            "hashed_password": record.hashed_password,
            "is_active": record.is_active,
            "user_tier": record.user_tier,
            "fitness_level": record.fitness_level,
            "goals": record.goals or [],
            "equipment": (
                [record.equipment] if record.equipment else []
            ),  # Convert single to list
            "created_at": record.created_at,
            "updated_at": record.updated_at,
        }

        return UserProfile(**db_dict)

    async def create(self, entity: UserProfile) -> UserProfile:
        # Get model data and exclude fields that don't exist in SQLAlchemy model
        model_data = entity.model_dump()
        # Remove available_equipment field as it doesn't exist in UserProfileDB
        model_data.pop("available_equipment", None)

        # Convert equipment list to single value for SQLAlchemy
        if "equipment" in model_data and isinstance(model_data["equipment"], list):
            # Take first equipment item or default to 'none'
            model_data["equipment"] = (
                model_data["equipment"][0] if model_data["equipment"] else "none"
            )

        db_obj = UserProfileDB(**model_data)  # type: ignore[arg-type]
        self._session.add(db_obj)
        self._session.commit()
        self._session.refresh(db_obj)

        # Convert SQLAlchemy object back to dict for Pydantic validation
        db_dict = {
            "id": db_obj.id,
            "email": db_obj.email,
            "username": db_obj.username,
            "hashed_password": db_obj.hashed_password,
            "is_active": db_obj.is_active,
            "user_tier": db_obj.user_tier,
            "fitness_level": db_obj.fitness_level,
            "goals": db_obj.goals or [],
            "equipment": (
                [db_obj.equipment] if db_obj.equipment else []
            ),  # Convert single to list
            "created_at": db_obj.created_at,
            "updated_at": db_obj.updated_at,
        }

        return UserProfile(**db_dict)

    async def update(self, entity: UserProfile) -> UserProfile:
        record = (
            self._session.query(UserProfileDB)
            .filter(UserProfileDB.id == entity.id)
            .first()
        )
        if record is None:
            raise ValueError("User not found")

        # Get model data and exclude fields that don't exist in SQLAlchemy model
        model_data = entity.model_dump()
        model_data.pop("available_equipment", None)

        # Convert equipment list to single value for SQLAlchemy
        if "equipment" in model_data and isinstance(model_data["equipment"], list):
            # Take first equipment item or default to 'none'
            model_data["equipment"] = (
                model_data["equipment"][0] if model_data["equipment"] else "none"
            )

        for field, value in model_data.items():
            if value is not None:
                setattr(record, field, value)
        record.updated_at = datetime.utcnow()
        self._session.commit()
        self._session.refresh(record)

        # Convert SQLAlchemy object back to dict for Pydantic validation
        db_dict = {
            "id": record.id,
            "email": record.email,
            "username": record.username,
            "hashed_password": record.hashed_password,
            "is_active": record.is_active,
            "user_tier": record.user_tier,
            "fitness_level": record.fitness_level,
            "goals": record.goals or [],
            "equipment": (
                [record.equipment] if record.equipment else []
            ),  # Convert single to list
            "created_at": record.created_at,
            "updated_at": record.updated_at,
        }

        return UserProfile(**db_dict)

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

        # Convert each SQLAlchemy object to Pydantic with proper field handling
        result = []
        for record in records:
            db_dict = {
                "id": record.id,
                "email": record.email,
                "username": record.username,
                "hashed_password": record.hashed_password,
                "is_active": record.is_active,
                "user_tier": record.user_tier,
                "fitness_level": record.fitness_level,
                "goals": record.goals or [],
                "equipment": (
                    [record.equipment] if record.equipment else []
                ),  # Convert single to list
                "created_at": record.created_at,
                "updated_at": record.updated_at,
            }
            result.append(UserProfile(**db_dict))

        return result

    # Alias for backward compatibility
    async def add(self, entity: UserProfile) -> UserProfile:
        """Alias for create method."""
        return await self.create(entity)
