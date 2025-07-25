#!/usr/bin/env python3
"""Test script to verify all critical dependencies are working"""


def test_imports():
    """Test all critical imports for Vigor backend"""
    print("🔍 Testing Vigor backend dependencies...")

    try:
        import psycopg2

        print("✅ psycopg2:", psycopg2.__version__)
    except ImportError as e:
        print("❌ psycopg2 import failed:", e)
        return False

    try:
        import fastapi

        print("✅ FastAPI:", fastapi.__version__)
    except ImportError as e:
        print("❌ FastAPI import failed:", e)
        return False

    try:
        import sqlalchemy

        print("✅ SQLAlchemy:", sqlalchemy.__version__)
    except ImportError as e:
        print("❌ SQLAlchemy import failed:", e)
        return False

    try:
        import uvicorn

        print("✅ Uvicorn:", uvicorn.__version__)
    except ImportError as e:
        print("❌ Uvicorn import failed:", e)
        return False

    try:
        import openai

        print("✅ OpenAI:", openai.__version__)
    except ImportError as e:
        print("❌ OpenAI import failed:", e)
        return False

    try:
        import azure.identity

        print("✅ Azure Identity: imported successfully")
    except ImportError as e:
        print("❌ Azure Identity import failed:", e)
        return False

    try:
        import alembic

        print("✅ Alembic:", alembic.__version__)
    except ImportError as e:
        print("❌ Alembic import failed:", e)
        return False

    print("\n🎉 All critical dependencies are working!")
    return True


if __name__ == "__main__":
    success = test_imports()
    exit(0 if success else 1)
