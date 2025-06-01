from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

# Get database URL from environment variable
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./vigor.db")

# Create SQLAlchemy engine
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
)

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class
Base = declarative_base()

def init_db():
    """Initialize database tables."""
    # Import all the SQLAlchemy models here to make sure they are registered
    try:
        from database.sql_models import (
            UserProfileDB, WorkoutPlanDB, WorkoutLogDB, ProgressMetricsDB, 
            AICoachMessageDB, ChatMessageDB, AIProviderPriorityDB, 
            BudgetSettingsDB, AIUsageLogDB, AdminSettingsDB
        )
        # Create all tables
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables initialized successfully")
    except Exception as e:
        print(f"⚠️ Database initialization error: {e}")
        # Continue anyway - tables might already exist

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close() 