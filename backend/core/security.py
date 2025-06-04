from datetime import datetime, timedelta
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from database.connection import get_db
from database.models import UserProfile
from database.sql_models import UserProfileDB

from .config import get_settings

settings = get_settings()

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash."""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Generate password hash."""
    return pwd_context.hash(password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def verify_token(token: str) -> dict:
    """Verify and decode JWT token."""
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)
) -> UserProfile:
    """Get current user from JWT token."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(UserProfileDB).filter(UserProfileDB.id == user_id).first()
    if user is None:
        raise credentials_exception

    # Convert SQLAlchemy model to Pydantic model
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


async def get_current_active_user(
    current_user: UserProfile = Depends(get_current_user),
) -> UserProfile:
    """Get current active user."""
    # Add any additional checks for user status here
    return current_user


async def get_current_admin_user(
    current_user: UserProfile = Depends(get_current_user),
) -> UserProfile:
    """
    Verify that the current user has admin privileges.
    """
    # Check if user has admin role/permissions
    # For now, we'll check if user has an 'is_admin' field or admin role
    if hasattr(current_user, "is_admin") and current_user.is_admin:
        return current_user

    # Alternative: check for admin role in user profile
    if hasattr(current_user, "role") and current_user.role == "admin":
        return current_user

    # Alternative: check email domain or specific user IDs
    # This is a fallback - in production you'd have proper role management
    admin_emails = [
        "admin@vigor.com",
        "admin@example.com",
    ]  # Configure based on your needs
    if hasattr(current_user, "email") and current_user.email in admin_emails:
        return current_user

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required"
    )
