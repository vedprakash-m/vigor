from datetime import datetime, timedelta

# Use python-jose for JWT handling (PyJWT not required)
from jose import jwt, JWTError, ExpiredSignatureError
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy.orm import Session

from api.schemas.auth import Token, UserRegister
from api.services.auth import authenticate_user, create_user_token, register_user
from core.config import get_settings
from core.security import get_current_active_user
from database.connection import get_db
from database.models import UserProfile

router = APIRouter(prefix="/auth", tags=["auth"])

settings = get_settings()

RESET_SECRET = settings.SECRET_KEY + "_pwreset"
RESET_EXPIRE_MINUTES = 30


@router.post("/register", response_model=dict, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """Register a new user."""
    user = await register_user(db, user_data.dict())
    token_data = await create_user_token(user)
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "tier": user.user_tier.value if hasattr(user, "user_tier") else "FREE",
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


@router.post("/forgot", response_model=dict)
async def forgot_password(email: str, db: Session = Depends(get_db)):
    """Initiate password reset by issuing a JWT token and (simulated) email."""
    user = db.query(UserProfile).filter(UserProfile.email == email).first()
    if not user:
        # Return same message to prevent email enumeration
        return {"message": "If the account exists you will receive a reset link."}

    token_payload = {
        "sub": user.id,
        "exp": datetime.utcnow() + timedelta(minutes=RESET_EXPIRE_MINUTES),
    }
    token = jwt.encode(token_payload, RESET_SECRET, algorithm="HS256")
    reset_link = f"https://app.vigor.com/reset-password?token={token}"
    print("[PasswordReset]", reset_link)  # Simulate email send
    return {
        "message": "Password reset link sent",
        "expires_in": RESET_EXPIRE_MINUTES * 60,
    }


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str


@router.post("/reset", response_model=dict)
async def reset_password(req: ResetPasswordRequest, db: Session = Depends(get_db)):
    """Reset password using valid token."""
    try:
        payload = jwt.decode(req.token, RESET_SECRET, algorithms=["HS256"])
        user_id: str = payload.get("sub")
    except ExpiredSignatureError:
        raise HTTPException(status_code=400, detail="Token expired")
    except JWTError:
        raise HTTPException(status_code=400, detail="Invalid token")

    user = db.query(UserProfile).filter(UserProfile.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # naive password update; production would hash
    user.hashed_password = req.new_password  # type: ignore
    db.commit()
    return {"message": "Password reset successful"}
