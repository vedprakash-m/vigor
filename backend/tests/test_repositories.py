import uuid
from datetime import datetime

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.connection import Base
from database.sql_models import UserProfileDB
from domain.repositories.base import BaseRepository as Repository
from infrastructure.repositories.sqlalchemy_progress_repository import (
    SQLAlchemyProgressRepository,
)
from infrastructure.repositories.sqlalchemy_user_repository import (
    SQLAlchemyUserRepository,
)


@pytest.fixture(scope="function")
def session():
    engine = create_engine(
        "sqlite:///:memory:", connect_args={"check_same_thread": False}
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    # create tables
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.mark.asyncio
async def test_user_repository_crud(session):
    repo: Repository = SQLAlchemyUserRepository(session)

    # add
    user_id = str(uuid.uuid4())
    user_obj = UserProfileDB(
        id=user_id,
        email="a@b.com",
        username="alice",
        hashed_password="hashed_password_here",
        goals=[],
        fitness_level="beginner",
        equipment="none",
        injuries=[],
        preferences={},
        user_tier="free",
        monthly_budget=0.0,
        current_month_usage=0.0,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    # Use repo.add via model_validate for speed
    from database.models import UserProfile

    # Convert SQLAlchemy object to dict first for proper validation
    user_dict = {
        "id": user_obj.id,
        "email": user_obj.email,
        "username": user_obj.username,
        "hashed_password": user_obj.hashed_password,
        "is_active": True,
        "user_tier": user_obj.user_tier,
        "fitness_level": user_obj.fitness_level,
        "goals": user_obj.goals,
        "equipment": ["none"],
        "created_at": user_obj.created_at,
        "updated_at": user_obj.updated_at,
    }

    added = await repo.add(UserProfile(
        id=user_obj.id,
        email=user_obj.email,
        username=user_obj.username,
        hashed_password=user_obj.hashed_password,
        user_tier=user_obj.user_tier,
        fitness_level=user_obj.fitness_level,
        goals=user_obj.goals,
        equipment=["none"],
        created_at=user_obj.created_at,
        updated_at=user_obj.updated_at,
    ))
    assert added.id == user_id

    fetched = await repo.get(user_id)
    assert fetched.email == "a@b.com"

    # Update the user - create updated UserProfile object
    updated_user = UserProfile(
        id=user_id,
        email="a@b.com",
        username="alice2",  # Updated username
        hashed_password="hashed_password_here",
        user_tier="free",
        fitness_level="beginner",
        goals=[],
        equipment=["none"],
        created_at=user_obj.created_at,
        updated_at=datetime.utcnow(),
    )
    updated = await repo.update(updated_user)
    assert updated.username == "alice2"


@pytest.mark.asyncio
async def test_progress_repository(session):
    progress_repo = SQLAlchemyProgressRepository(session)
    user_repo = SQLAlchemyUserRepository(session)

    # ensure user exists
    user_id = str(uuid.uuid4())
    from database.models import UserProfile

    await user_repo.add(
        UserProfile(
            id=user_id,
            email="x@y.com",
            username="bob",
            hashed_password="hashed_password_here",  # Required field
            goals=[],
            fitness_level="beginner",
            equipment=["none"],  # Must be list format for Pydantic
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
    )

    metric_id = str(uuid.uuid4())
    from database.models import ProgressMetrics

    # Create ProgressMetrics with only fields that exist in SQLAlchemy model
    # Note: SQLAlchemy model has 'date' field, Pydantic has 'metric_date'
    metric = ProgressMetrics(
        id=metric_id,
        user_id=user_id,
        metric_date=datetime.utcnow().date(),  # Pydantic field name
        # Only include fields that exist in SQLAlchemy: weight, body_fat, notes
        # Skip the workout tracking fields that don't exist in SQLAlchemy
        created_at=datetime.utcnow(),
    )

    added = await progress_repo.add(metric)
    assert added.id == metric_id

    all_metrics = await progress_repo.list(limit=10)
    assert len(all_metrics) == 1
