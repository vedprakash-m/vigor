"""
Health Check Blueprint
Endpoints: health, health-simple
"""

import logging
from datetime import datetime, timezone

import azure.functions as func

from shared.helpers import success_response

logger = logging.getLogger(__name__)

health_bp = func.Blueprint()


@health_bp.route(
    route="health", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS
)
async def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Health check with dependency verification"""
    try:
        from shared.cosmos_db import get_global_client
        from shared.openai_client import OpenAIClient

        client = await get_global_client()
        cosmos_health = await client.health_check()

        ai_client = OpenAIClient()
        ai_health = ai_client.is_available()

        healthy = cosmos_health and ai_health
        health_status = {
            "status": "healthy" if healthy else "unhealthy",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "services": {
                "cosmos_db": "healthy" if cosmos_health else "unhealthy",
                "azure_openai": "healthy" if ai_health else "unhealthy",
            },
            "version": "3.0.0-ghost",
        }

        return success_response(health_status, status_code=200 if healthy else 503)

    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return success_response(
            {
                "status": "unhealthy",
                "error": str(e),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            },
            status_code=503,
        )


@health_bp.route(
    route="health-simple", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS
)
async def health_simple(req: func.HttpRequest) -> func.HttpResponse:
    """Simple health check — no external dependencies"""
    return success_response(
        {
            "status": "healthy",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "message": "Function App is running",
            "version": "3.0.0-ghost",
        }
    )
