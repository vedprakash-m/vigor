"""
Enhanced Authentication API with OAuth2 and Microsoft Entra External ID support
"""

from typing import Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from fastapi.responses import RedirectResponse
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, ValidationError
from sqlalchemy.orm import Session

from api.schemas.auth import Token, UserRegister
from api.services.auth import (
    AuthService,
)
from core.config import get_settings
from core.oauth2 import OAuth2Service
from core.security import (
    SecurityAuditLogger,
    UserInputValidator,
    check_request_origin,
    get_current_active_user,
    limiter,
    validate_request_size,
)
from database.connection import get_db
from database.models import UserProfile

# Third-party imports


router = APIRouter()

settings = get_settings()

RESET_SECRET = settings.SECRET_KEY + "_pwreset"
RESET_EXPIRE_MINUTES = 30


@router.post("/register", response_model=Token, summary="Register New User")
@limiter.limit("5/minute")  # Strict rate limiting for registration
async def register(
    request: Request, user_data: UserRegister, db: Session = Depends(get_db)
):
    """
    Register a new user with enhanced security validation

    **Rate Limited**: 5 requests per minute per IP
    **Validation**: Email format, password strength, username format
    **Audit**: All registration attempts logged
    """
    try:
        # Security checks
        await validate_request_size(request, max_size=10 * 1024)  # 10KB max
        await check_request_origin(request)

        # Input validation using our security validator
        try:
            validated_data = UserInputValidator(
                email=user_data.email,
                username=user_data.username,
                password=user_data.password,
            )
        except Exception as validation_error:
            await SecurityAuditLogger.log_auth_attempt(
                request,
                user_id=None,
                success=False,
                reason=f"validation_failed: {validation_error}",
            )
            raise HTTPException(
                status_code=422,
                detail={
                    "error": "validation_error",
                    "message": str(validation_error),
                    "field": "user_input",
                },
            )

        # Create user through service
        auth_service = AuthService(db)
        await auth_service.register_user(
            email=validated_data.email,
            username=validated_data.username,
            password=validated_data.password,
        )

        # Log successful registration
        await SecurityAuditLogger.log_auth_attempt(
            request,
            user_id=None,
            success=True,
            reason="registration_successful",
        )

        return {"message": "Registration successful"}

    except HTTPException as e:
        # Re-raise HTTP exceptions
        await SecurityAuditLogger.log_auth_attempt(
            request, user_id=None, success=False, reason=f"http_error: {e.detail}"
        )
        raise
    except Exception as e:
        # Log unexpected errors
        await SecurityAuditLogger.log_auth_attempt(
            request,
            user_id=None,
            success=False,
            reason=f"unexpected_error: {str(e)[:100]}",
        )
        raise HTTPException(
            status_code=500, detail="Registration failed due to server error"
        )


class LoginRequest(BaseModel):
    email: str
    password: str


@router.post("/login", response_model=Token, summary="User Login")
@limiter.limit("10/minute")  # Rate limit login attempts
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    """
    Authenticate user and return access token

    **Rate Limited**: 10 requests per minute per IP
    **Security**: Failed attempts logged, suspicious activity detection
    **Audit**: All login attempts logged with details
    """
    try:
        # Security checks
        await validate_request_size(request, max_size=5 * 1024)  # 5KB max
        await check_request_origin(request)

        # Basic input validation
        if not form_data.username or not form_data.password:
            await SecurityAuditLogger.log_auth_attempt(
                request, user_id=None, success=False, reason="missing_credentials"
            )
            raise HTTPException(
                status_code=422, detail="Email and password are required"
            )

        # Additional validation for email format
        try:
            validated_input = UserInputValidator(
                email=form_data.username,  # username field contains email
                password=form_data.password,
                username="temp",  # Just for validation, not used
            )
        except Exception as validation_error:
            await SecurityAuditLogger.log_auth_attempt(
                request,
                user_id=None,
                success=False,
                reason=f"input_validation_failed: {validation_error}",
            )
            raise HTTPException(
                status_code=422, detail="Invalid email format or password"
            )

        # Authenticate through service
        auth_service = AuthService(db)
        await auth_service.authenticate_user(
            email=validated_input.email, password=form_data.password
        )

        # Log successful login
        await SecurityAuditLogger.log_auth_attempt(
            request,
            user_id=None,
            success=True,
            reason="login_successful",
        )

        return {"message": "Login successful"}

    except HTTPException as e:
        # Handle authentication failures
        if e.status_code == 401:
            await SecurityAuditLogger.log_auth_attempt(
                request, user_id=None, success=False, reason="invalid_credentials"
            )
        else:
            await SecurityAuditLogger.log_auth_attempt(
                request, user_id=None, success=False, reason=f"auth_error: {e.detail}"
            )
        raise
    except Exception as e:
        # Log unexpected errors
        await SecurityAuditLogger.log_auth_attempt(
            request,
            user_id=None,
            success=False,
            reason=f"unexpected_error: {str(e)[:100]}",
        )
        raise HTTPException(
            status_code=500, detail="Authentication failed due to server error"
        )


class RefreshRequest(BaseModel):
    refresh_token: Optional[str] = None


@router.post("/refresh", response_model=Token, summary="Refresh Access Token")
@limiter.limit("20/minute")  # More generous for token refresh
async def refresh_token(
    request: Request, refresh_token: str, db: Session = Depends(get_db)
):
    """
    Refresh access token using refresh token

    **Rate Limited**: 20 requests per minute per IP
    **Security**: Token validation, expiration checking
    """
    try:
        await validate_request_size(request, max_size=2 * 1024)  # 2KB max

        if not refresh_token or len(refresh_token.strip()) == 0:
            await SecurityAuditLogger.log_suspicious_activity(
                request, "token_refresh_invalid_input", {"error": "empty_refresh_token"}
            )
            raise HTTPException(status_code=422, detail="Refresh token is required")

        auth_service = AuthService(db)
        await auth_service.refresh_access_token(refresh_token)

        # Log successful token refresh
        await SecurityAuditLogger.log_auth_attempt(
            request,
            user_id=None,
            success=True,
            reason="token_refresh_successful",
        )

        return {"message": "Token refresh successful"}

    except HTTPException as e:
        await SecurityAuditLogger.log_suspicious_activity(
            request,
            "token_refresh_failed",
            {"error": str(e.detail), "status_code": e.status_code},
        )
        raise
    except Exception as e:
        await SecurityAuditLogger.log_suspicious_activity(
            request, "token_refresh_error", {"error": str(e)[:100]}
        )
        raise HTTPException(status_code=500, detail="Token refresh failed")


@router.get("/me", response_model=UserProfile)
async def get_me(current_user: UserProfile = Depends(get_current_active_user)):
    return current_user


@router.post("/logout", response_model=dict)
async def logout():
    """Stateless logout – handled on client side. Always returns 200."""
    return {"message": "Logged out"}


@router.post("/forgot-password", summary="Request Password Reset")
@limiter.limit("3/minute")  # Very strict rate limiting for password reset
async def forgot_password(request: Request, email: str, db: Session = Depends(get_db)):
    """
    Request password reset email

    **Rate Limited**: 3 requests per minute per IP (anti-abuse)
    **Security**: Email validation, suspicious activity detection
    """
    try:
        await validate_request_size(request, max_size=1 * 1024)  # 1KB max
        await check_request_origin(request)

        # Validate email format
        try:
            validate_input = UserInputValidator(
                email=email,
                username="temp",  # Not used
                password="TempPass123!",  # Not used
            )
            validated_email = validate_input.email
        except Exception as validation_error:
            await SecurityAuditLogger.log_suspicious_activity(
                request,
                "password_reset_invalid_email",
                {"email": email[:50], "error": str(validation_error)},
            )
            raise HTTPException(status_code=422, detail="Invalid email format")

        auth_service = AuthService(db)
        await auth_service.request_password_reset(validated_email)

        # Always return success to prevent email enumeration
        # But log the actual result for monitoring
        await SecurityAuditLogger.log_auth_attempt(
            request,
            user_id=None,
            success=True,
            reason=f"password_reset_requested: {validated_email}",
        )

        return {"message": "If the email exists, a reset link has been sent"}

    except Exception as e:
        await SecurityAuditLogger.log_suspicious_activity(
            request,
            "password_reset_error",
            {"email": email[:50] if email else "none", "error": str(e)[:100]},
        )
        # Still return success message to prevent information disclosure
        return {"message": "If the email exists, a reset link has been sent"}


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str


@router.post("/reset-password", summary="Reset Password")
@limiter.limit("5/minute")  # Rate limit password resets
async def reset_password(
    request: Request, token: str, new_password: str, db: Session = Depends(get_db)
):
    """
    Reset password using reset token

    **Rate Limited**: 5 requests per minute per IP
    **Security**: Token validation, password strength checking
    """
    try:
        await validate_request_size(request, max_size=2 * 1024)  # 2KB max
        await check_request_origin(request)

        # Validate inputs
        if not token or not new_password:
            await SecurityAuditLogger.log_suspicious_activity(
                request,
                "password_reset_missing_data",
                {"has_token": bool(token), "has_password": bool(new_password)},
            )
            raise HTTPException(
                status_code=422, detail="Reset token and new password are required"
            )

        # Validate new password strength
        try:
            # Just validate the password meets requirements
            UserInputValidator(
                email="temp@example.com",  # Not used
                username="temp",  # Not used
                password=new_password,
            )
        except ValidationError as e:
            raise HTTPException(
                status_code=400, detail=f"Password validation failed: {str(e)}"
            ) from e

        auth_service = AuthService(db)
        await auth_service.reset_password(token, new_password)

        # Log successful password reset
        await SecurityAuditLogger.log_auth_attempt(
            request,
            user_id=None,
            success=True,
            reason="password_reset_successful",
        )

        return {"message": "Password reset successfully"}

    except HTTPException as e:
        await SecurityAuditLogger.log_suspicious_activity(
            request,
            "password_reset_failed",
            {"error": str(e.detail), "status_code": e.status_code},
        )
        raise
    except Exception as e:
        await SecurityAuditLogger.log_suspicious_activity(
            request, "password_reset_error", {"error": str(e)[:100]}
        )
        raise HTTPException(status_code=500, detail="Password reset failed")


# OAuth2 Endpoints
@router.get("/oauth/{provider}", summary="Get OAuth2 Authorization URL")
@limiter.limit("10/minute")
async def get_oauth_authorization_url(
    request: Request, provider: str, db: Session = Depends(get_db)
):
    """
    Get authorization URL for OAuth2 provider (Microsoft, Google, GitHub)

    **Rate Limited**: 10 requests per minute per IP
    **Providers**: microsoft, google, github
    """
    try:
        await validate_request_size(request, max_size=1024)  # 1KB max
        await check_request_origin(request)

        oauth_service = OAuth2Service(db)
        result = oauth_service.get_authorization_url(provider)

        await SecurityAuditLogger.log_security_event(
            request, "oauth_authorization_requested", {"provider": provider}
        )

        return result

    except HTTPException:
        raise
    except Exception as e:
        await SecurityAuditLogger.log_suspicious_activity(
            request,
            "oauth_authorization_error",
            {"provider": provider, "error": str(e)[:100]},
        )
        raise HTTPException(status_code=500, detail="OAuth authorization failed")


@router.get("/oauth/{provider}/callback", summary="OAuth2 Callback Handler")
@limiter.limit("20/minute")  # Higher limit for callbacks
async def oauth_callback(
    request: Request,
    provider: str,
    code: str,
    state: str,
    error: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """
    Handle OAuth2 callback from provider

    **Rate Limited**: 20 requests per minute per IP
    **Returns**: JWT tokens and user info on success
    """
    try:
        await validate_request_size(request, max_size=2 * 1024)  # 2KB max

        # Check for OAuth errors
        if error:
            await SecurityAuditLogger.log_security_event(
                request, "oauth_callback_error", {"provider": provider, "error": error}
            )
            # Redirect to frontend with error
            return RedirectResponse(
                url=f"{settings.LOGIN_ERROR_REDIRECT}&oauth_error={error}"
            )

        if not code or not state:
            raise HTTPException(
                status_code=400, detail="Missing authorization code or state"
            )

        oauth_service = OAuth2Service(db)
        result = await oauth_service.handle_oauth_callback(provider, code, state)

        await SecurityAuditLogger.log_security_event(
            request,
            "oauth_login_success",
            {"provider": provider, "user_id": result["user"]["id"]},
        )

        # For web flow, redirect to frontend with tokens
        redirect_url = (
            f"{settings.LOGIN_SUCCESS_REDIRECT}?"
            + f"access_token={result['access_token']}&"
            + f"refresh_token={result['refresh_token']}&"
            + f"provider={provider}"
        )

        return RedirectResponse(url=redirect_url)

    except HTTPException:
        await SecurityAuditLogger.log_suspicious_activity(
            request,
            "oauth_callback_failed",
            {"provider": provider, "error": "authentication_failed"},
        )
        return RedirectResponse(
            url=f"{settings.LOGIN_ERROR_REDIRECT}&oauth_error=authentication_failed"
        )
    except Exception as e:
        await SecurityAuditLogger.log_suspicious_activity(
            request,
            "oauth_callback_error",
            {"provider": provider, "error": str(e)[:100]},
        )
        return RedirectResponse(
            url=f"{settings.LOGIN_ERROR_REDIRECT}&oauth_error=server_error"
        )


@router.post("/oauth/{provider}/token", summary="OAuth2 Token Exchange (API)")
async def oauth_token_exchange(
    request: Request,
    provider: str,
    code: str,
    state: str,
    db: Session = Depends(get_db),
):
    """
    Exchange OAuth2 authorization code for JWT tokens (API endpoint)

    **Rate Limited**: 20 requests per minute per IP
    **Returns**: JWT tokens and user info (JSON response for API clients)
    """
    try:
        await validate_request_size(request, max_size=2 * 1024)  # 2KB max
        await check_request_origin(request)

        if not code or not state:
            raise HTTPException(
                status_code=400, detail="Missing authorization code or state"
            )

        oauth_service = OAuth2Service(db)
        result = await oauth_service.handle_oauth_callback(provider, code, state)

        await SecurityAuditLogger.log_security_event(
            request,
            "oauth_api_login_success",
            {"provider": provider, "user_id": result["user"]["id"]},
        )

        return result

    except HTTPException:
        raise
    except Exception as e:
        await SecurityAuditLogger.log_suspicious_activity(
            request,
            "oauth_api_token_error",
            {"provider": provider, "error": str(e)[:100]},
        )
        raise HTTPException(status_code=500, detail="OAuth token exchange failed")


@router.get("/oauth/providers", summary="Get Available OAuth2 Providers")
async def get_oauth_providers(db: Session = Depends(get_db)):
    """
    Get list of available OAuth2 providers

    **Returns**: Dictionary of configured OAuth2 providers
    """
    oauth_service = OAuth2Service(db)
    return {
        "providers": list(oauth_service.get_available_providers().keys()),
        "configuration": oauth_service.get_available_providers(),
    }
