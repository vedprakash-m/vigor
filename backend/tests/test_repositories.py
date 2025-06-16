import asyncio
import uuid
from datetime import datetime

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.connection import Base
from database.sql_models import ProgressMetricsDB, UserProfileDB
from domain.repositories.base import Repository
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
        hashed_password="x",
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

    added = await repo.add(UserProfile.model_validate(user_obj))
    assert added.id == user_id

    fetched = await repo.get(user_id)
    assert fetched.email == "a@b.com"

    updated = await repo.update(user_id, {"username": "alice2"})
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
    )

    metric_id = str(uuid.uuid4())
    from database.models import ProgressMetrics

    metric = ProgressMetrics(
        id=metric_id,
        user_id=user_id,
        date=datetime.utcnow(),
        weight=70.0,
        body_fat=20.0,
        measurements=None,
        notes="good",
        created_at=datetime.utcnow(),
    )

    added = await progress_repo.add(metric)
    assert added.id == metric_id

    all_metrics = await progress_repo.list(user_id=user_id, limit=10)
    assert len(all_metrics) == 1
