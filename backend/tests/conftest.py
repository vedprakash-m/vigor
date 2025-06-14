# flake8: noqa

import sys
from pathlib import Path

import pytest

# Ensure project root is in PYTHONPATH when tests are executed from within the
# backend directory (e.g., on CI/CD runners) so that `import database` works
PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.connection import Base, get_db
from main import app

# Test database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture
def db_session():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    return TestClient(app)


@pytest.fixture
def test_user():
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpassword123",
        "fitness_level": "beginner",
        "goals": ["endurance"],
        "equipment": "minimal",
    }


@pytest.fixture
def admin_user():
    return {
        "username": "adminuser",
        "email": "admin@example.com",
        "password": "adminpassword123",
        "fitness_level": "intermediate",
        "goals": ["muscle_gain"],
        "equipment": "full",
    }


@pytest.fixture
def mock_llm_response():
    return {
        "response": "Great workout today! Keep up the good work.",
        "provider": "gemini-flash-2.5",
        "cost": 0.001,
        "tokens_used": 25,
    }
