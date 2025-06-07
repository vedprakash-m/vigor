import uuid
from datetime import datetime, timedelta
from typing import Optional

from core.config import get_settings
from core.security import (create_access_token, get_password_hash,
                           verify_password, verify_token)
from database.connection import get_db
from database.models import UserProfile
from database.sql_models import UserProfileDB
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

settings = get_settings()
security = HTTPBearer()


async def register_user(db: Session, user_data: dict) -> UserProfile:
    """Register a new user."""
    # Check if user with email already exists
    if (
        db.query(UserProfileDB)
        .filter(UserProfileDB.email == user_data["email"])
        .first()
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered"
        )

    # Check if username is taken
    if (
        db.query(UserProfileDB)
        .filter(UserProfileDB.username == user_data["username"])
        .first()
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Username already taken"
        )

    # Create new user
    db_user = UserProfileDB(
        id=str(uuid.uuid4()),
        email=user_data["email"],
        username=user_data["username"],
        fitness_level=user_data["fitness_level"],
        goals=user_data["goals"],
        equipment=user_data["equipment"],
        hashed_password=get_password_hash(user_data["password"]),
    )

    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    # Convert to Pydantic model
    return UserProfile(
        id=db_user.id,
        email=db_user.email,
        username=db_user.username,
        fitness_level=db_user.fitness_level,
        goals=db_user.goals or [],
        equipment=db_user.equipment,
        injuries=db_user.injuries or [],
        preferences=db_user.preferences or {},
        created_at=db_user.created_at,
        updated_at=db_user.updated_at,
    )


async def authenticate_user(
    db: Session, email: str, password: str
) -> Optional[UserProfile]:
    """Authenticate a user."""
    user = db.query(UserProfileDB).filter(UserProfileDB.email == email).first()
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None

    return UserProfile(
        id=user.id,
        email=user.email,
        username=user.username,
        fitness_level=user.fitness_level,
        goals=user.goals or [],
        equipment=user.equipment,
        injuries=user.injuries or [],
        preferences=user.preferences or {},
        created_at=user.created_at,
        updated_at=user.updated_at,
    )


async def create_user_token(user: UserProfile) -> dict:
    """Create access token for user."""
    expires_delta = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.id}, expires_delta=expires_delta
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_at": datetime.utcnow() + expires_delta,
    }


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> UserProfile:
    """Get current user from JWT token."""
    try:
        token = credentials.credentials
        payload = verify_token(token)
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user = db.query(UserProfileDB).filter(UserProfileDB.id == user_id).first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return UserProfile(
        id=user.id,
        email=user.email,
        username=user.username,
        fitness_level=user.fitness_level,
        goals=user.goals or [],
        equipment=user.equipment,
        injuries=user.injuries or [],
        preferences=user.preferences or {},
        created_at=user.created_at,
        updated_at=user.updated_at,
    )
