"""
Authentication & User Management Blueprint
Endpoints: auth/me, users/profile, user/profile
"""

import logging

import azure.functions as func

from shared.auth import get_current_user_from_token
from shared.helpers import error_response, success_response

logger = logging.getLogger(__name__)

auth_bp = func.Blueprint()


@auth_bp.route(route="auth/me", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def get_current_user(req: func.HttpRequest) -> func.HttpResponse:
    """Get current user profile from Microsoft Entra ID token"""
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response(
                "Unauthorized - Valid Microsoft Entra ID token required",
                status_code=401,
                code="UNAUTHORIZED",
            )

        client = await get_global_client()
        profile = await client.get_user_profile(current_user["email"])
        if not profile:
            profile = {
                "id": current_user["email"],
                "email": current_user["email"],
                "username": current_user.get(
                    "username", current_user["email"].split("@")[0]
                ),
                "tier": current_user.get("tier", "free"),
                "fitness_level": "beginner",
                "fitness_goals": ["general_fitness"],
                "available_equipment": ["none"],
            }

        return success_response(profile)

    except Exception as e:
        logger.error(f"Error getting current user: {str(e)}")
        return error_response("Internal server error", status_code=500)


@auth_bp.route(
    route="users/profile", methods=["GET", "PUT"], auth_level=func.AuthLevel.ANONYMOUS
)
async def user_profile(req: func.HttpRequest) -> func.HttpResponse:
    """Get or update user profile"""
    try:
        from shared.cosmos_db import get_global_client
        from shared.rate_limiter import RateLimiter

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        client = await get_global_client()

        if req.method == "GET":
            profile = await client.get_user_profile(current_user["email"])
            return success_response(profile)

        elif req.method == "PUT":
            rate_limiter = RateLimiter()
            if not await rate_limiter.check_rate_limit(
                key=f"profile_update:{current_user['email']}",
                limit=10,
                window=3600,
            ):
                return error_response(
                    "Rate limit exceeded", status_code=429, code="RATE_LIMITED"
                )

            try:
                profile_data = req.get_json()
            except ValueError:
                return error_response(
                    "Invalid JSON in request body",
                    status_code=400,
                    code="INVALID_JSON",
                )

            updated_profile = await client.update_user_profile(
                current_user["email"], profile_data
            )
            return success_response(updated_profile)

        return error_response("Method not allowed", status_code=405)

    except Exception as e:
        logger.error(f"Error in user profile: {str(e)}")
        return error_response("Internal server error", status_code=500)


@auth_bp.route(
    route="user/profile", methods=["GET", "PUT"], auth_level=func.AuthLevel.ANONYMOUS
)
async def user_profile_alias(req: func.HttpRequest) -> func.HttpResponse:
    """Alias for users/profile — iOS ``fetchUserProfile`` / ``updateUserProfile``"""
    return await user_profile(req)
