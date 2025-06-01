from .connection import engine, Base
from .sql_models import UserProfileDB, WorkoutPlanDB, WorkoutLogDB, ProgressMetricsDB, AICoachMessageDB

def init_db():
    """Initialize the database by creating all tables."""
    Base.metadata.create_all(bind=engine)

if __name__ == "__main__":
    print("Creating database tables...")
    init_db()
    print("Database tables created successfully!") 