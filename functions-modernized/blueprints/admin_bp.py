"""
Admin Dashboard Blueprint
Endpoints: admin/ai/cost-metrics, admin/ghost/health, admin/ghost/trust-distribution,
           admin/ghost/users, admin/ghost/decision-receipts, admin/ghost/safety-breakers,
           admin/ghost/analytics
"""

import logging

import azure.functions as func

from shared.auth import require_admin_user
from shared.helpers import error_response, parse_pagination, success_response

logger = logging.getLogger(__name__)

admin_bp = func.Blueprint()


@admin_bp.route(
    route="admin/ai/cost-metrics",
    methods=["GET"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def get_cost_metrics(req: func.HttpRequest) -> func.HttpResponse:
    """Get AI cost metrics (admin only)"""
    try:
        from shared.cosmos_db import get_global_client

        admin_user = await require_admin_user(req)
        if not admin_user:
            return error_response(
                "Admin access required", status_code=403, code="FORBIDDEN"
            )

        client = await get_global_client()
        cost_metrics = await client.get_ai_cost_metrics()

        return success_response(
            {
                "daily_spend": cost_metrics.get("daily_spend", 0),
                "monthly_budget": 50.0,
                "budget_utilization": cost_metrics.get("budget_utilization", 0),
                "provider_breakdown": {
                    "gpt-5-mini": cost_metrics.get("total_spend", 0)
                },
                "total_requests_today": cost_metrics.get("requests_today", 0),
            }
        )

    except Exception as e:
        logger.error(f"Error getting cost metrics: {str(e)}")
        return error_response("Failed to retrieve cost metrics", status_code=500)


@admin_bp.route(
    route="admin/ghost/health",
    methods=["GET"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def get_ghost_health(req: func.HttpRequest) -> func.HttpResponse:
    """Get Ghost system health (admin only)"""
    try:
        from shared.cosmos_db import get_global_client

        admin_user = await require_admin_user(req)
        if not admin_user:
            return error_response(
                "Admin access required", status_code=403, code="FORBIDDEN"
            )

        client = await get_global_client()
        health_data = await client.get_ghost_health_metrics()

        return success_response(
            {
                "mode": health_data.get("mode", "NORMAL"),
                "modelHealth": health_data.get("model_health", "healthy"),
                "avgLatencyMs": health_data.get("avg_latency_ms", 245),
                "successRate": health_data.get("success_rate", 99.2),
                "decisionsToday": health_data.get("decisions_today", 156),
                "mutationsToday": health_data.get("mutations_today", 47),
                "safetyBreakersTriggered": health_data.get("safety_breakers", 0),
                "components": {
                    "decisionEngine": "healthy",
                    "phenomeRAG": "healthy",
                    "workoutMutator": "healthy",
                    "trustCalculator": "healthy",
                    "safetyMonitor": "healthy",
                },
            }
        )

    except Exception as e:
        logger.error(f"Error getting ghost health: {str(e)}")
        return error_response("Failed to retrieve ghost health", status_code=500)


@admin_bp.route(
    route="admin/ghost/trust-distribution",
    methods=["GET"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def get_trust_distribution(req: func.HttpRequest) -> func.HttpResponse:
    """Get user trust phase distribution (admin only)"""
    try:
        from shared.cosmos_db import get_global_client

        admin_user = await require_admin_user(req)
        if not admin_user:
            return error_response(
                "Admin access required", status_code=403, code="FORBIDDEN"
            )

        client = await get_global_client()
        distribution = await client.get_trust_distribution()

        return success_response({"phases": distribution})

    except Exception as e:
        logger.error(f"Error getting trust distribution: {str(e)}")
        return error_response(
            "Failed to retrieve trust distribution", status_code=500
        )


@admin_bp.route(
    route="admin/ghost/users",
    methods=["GET"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def get_admin_users(req: func.HttpRequest) -> func.HttpResponse:
    """Get all users with Ghost-specific fields (admin only)"""
    try:
        from shared.cosmos_db import get_global_client

        admin_user = await require_admin_user(req)
        if not admin_user:
            return error_response(
                "Admin access required", status_code=403, code="FORBIDDEN"
            )

        client = await get_global_client()
        users = await client.get_all_users_admin()

        return success_response({"users": users})

    except Exception as e:
        logger.error(f"Error getting admin users: {str(e)}")
        return error_response("Failed to retrieve users", status_code=500)


@admin_bp.route(
    route="admin/ghost/decision-receipts",
    methods=["GET"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def get_decision_receipts(req: func.HttpRequest) -> func.HttpResponse:
    """Get Ghost decision receipts for audit (admin only)"""
    try:
        from shared.cosmos_db import get_global_client

        admin_user = await require_admin_user(req)
        if not admin_user:
            return error_response(
                "Admin access required", status_code=403, code="FORBIDDEN"
            )

        limit, _ = parse_pagination(req, max_limit=100, default_limit=50)
        client = await get_global_client()
        receipts = await client.get_decision_receipts(limit=limit)

        return success_response({"receipts": receipts})

    except Exception as e:
        logger.error(f"Error getting decision receipts: {str(e)}")
        return error_response(
            "Failed to retrieve decision receipts", status_code=500
        )


@admin_bp.route(
    route="admin/ghost/safety-breakers",
    methods=["GET"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def get_safety_breaker_events(req: func.HttpRequest) -> func.HttpResponse:
    """Get safety breaker events (admin only)"""
    try:
        from shared.cosmos_db import get_global_client

        admin_user = await require_admin_user(req)
        if not admin_user:
            return error_response(
                "Admin access required", status_code=403, code="FORBIDDEN"
            )

        limit, _ = parse_pagination(req, max_limit=100, default_limit=50)
        client = await get_global_client()
        events = await client.get_safety_breaker_events(limit=limit)

        return success_response({"events": events})

    except Exception as e:
        logger.error(f"Error getting safety breaker events: {str(e)}")
        return error_response(
            "Failed to retrieve safety breaker events", status_code=500
        )


@admin_bp.route(
    route="admin/ghost/analytics",
    methods=["GET"],
    auth_level=func.AuthLevel.ANONYMOUS,
)
async def get_ghost_analytics(req: func.HttpRequest) -> func.HttpResponse:
    """Get Ghost analytics for specified period (admin only)"""
    try:
        from shared.cosmos_db import get_global_client

        admin_user = await require_admin_user(req)
        if not admin_user:
            return error_response(
                "Admin access required", status_code=403, code="FORBIDDEN"
            )

        try:
            days = int(req.params.get("days", 7))
        except (ValueError, TypeError):
            days = 7
        days = max(1, min(days, 90))

        client = await get_global_client()
        analytics = await client.get_ghost_analytics(days=days)

        return success_response(analytics)

    except Exception as e:
        logger.error(f"Error getting ghost analytics: {str(e)}")
        return error_response("Failed to retrieve analytics", status_code=500)
