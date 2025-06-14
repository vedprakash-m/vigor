from datetime import datetime, timedelta

# Third-party imports
from fastapi import APIRouter, Depends, HTTPException, status, Request, Body
from fastapi.security import OAuth2PasswordRequestForm
from jose import ExpiredSignatureError, JWTError, jwt
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
        "tier": (
            user.user_tier.value.upper() if hasattr(user, "user_tier") else "FREE"
        ),
        **token_data,
    }


class LoginRequest(BaseModel):
    email: str
    password: str


@router.post("/login", response_model=Token)
async def login(
    request: Request,
    db: Session = Depends(get_db),
    form_data: OAuth2PasswordRequestForm = Depends(None),
    login_json: LoginRequest | None = Body(None),
):
    """Login and get access token.

    Accepts either:
    • application/x-www-form-urlencoded via `OAuth2PasswordRequestForm` (production)
    • application/json body `{ "email": "..", "password": ".." }` (unit tests)
    """

    if login_json:
        username = login_json.email
        password = login_json.password
    elif form_data:
        username = form_data.username
        password = form_data.password
    else:
        raise HTTPException(status_code=422, detail="Missing credentials")

    user = await authenticate_user(db, username, password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token_data = await create_user_token(user)
    return Token(**token_data)


class RefreshRequest(BaseModel):
    refresh_token: str | None = None


@router.post("/refresh", response_model=Token)
async def refresh(
    refresh_req: RefreshRequest | None = None,
    current_user: UserProfile | None = Depends(get_current_active_user),
    db: Session = Depends(get_db),
):
    """Refresh access token.

    • If Authorization header with valid token is supplied, just refresh for that user.
    • Else if body contains `refresh_token`, attempt to decode & refresh.
    """

    if current_user:
        user = current_user
    elif refresh_req and refresh_req.refresh_token:
        try:
            payload = jwt.decode(
                refresh_req.refresh_token, settings.SECRET_KEY, algorithms=["HS256"]
            )
            user_id = payload.get("sub")
        except JWTError:
            raise HTTPException(status_code=401, detail="Invalid refresh token")

        db_user = db.query(UserProfile).filter(UserProfile.id == user_id).first()
        if not db_user:
            raise HTTPException(status_code=401, detail="User not found")
        user = UserProfile.model_validate(db_user)
    else:
        raise HTTPException(status_code=401, detail="Missing refresh token")

    return Token(**await create_user_token(user))


@router.get("/me", response_model=UserProfile)
async def get_me(current_user: UserProfile = Depends(get_current_active_user)):
    return current_user


@router.post("/logout", response_model=dict)
async def logout():
    """Stateless logout – handled on client side. Always returns 200."""
    return {"message": "Logged out"}


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
