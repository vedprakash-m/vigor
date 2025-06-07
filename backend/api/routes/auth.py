from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from api.schemas.auth import Token, UserRegister
from api.services.auth import (authenticate_user, create_user_token,
                               register_user)
from core.security import get_current_active_user
from database.connection import get_db
from database.models import UserProfile

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=dict)
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """Register a new user."""
    user = await register_user(db, user_data.dict())
    token_data = await create_user_token(user)
    return {
        "message": "User registered successfully",
        "user": {"id": user.id, "email": user.email, "username": user.username},
        **token_data,
    }


@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)
):
    """Login and get access token."""
    user = await authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token_data = await create_user_token(user)
    return Token(**token_data)


@router.post("/refresh", response_model=Token)
async def refresh(current_user: UserProfile = Depends(get_current_active_user)):
    """Refresh access token."""
    token_data = await create_user_token(current_user)
    return Token(**token_data)
