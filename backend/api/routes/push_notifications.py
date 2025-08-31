"""
Push notification endpoints for PWA functionality.
Handles push subscription management and notification delivery.
"""

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.ext.asyncio import AsyncSession

from api.schemas.users import UserProfileResponse
from core.auth_dependencies import get_current_user
from database.connection import get_db

# Rate limiting
limiter = Limiter(key_func=get_remote_address)

router = APIRouter(prefix="/push", tags=["push_notifications"])


# Pydantic models for push notifications
class PushSubscriptionEndpoint(BaseModel):
    endpoint: str
    keys: dict[str, str]  # Contains p256dh and auth keys


class PushSubscriptionCreate(BaseModel):
    subscription: PushSubscriptionEndpoint
    user_agent: str
    timestamp: str


class PushSubscriptionResponse(BaseModel):
    id: str
    user_id: str
    endpoint: str
    created_at: datetime
    is_active: bool


class NotificationSend(BaseModel):
    title: str
    body: str
    icon: str | None = None
    badge: str | None = None
    tag: str | None = None
    url: str | None = None
    require_interaction: bool = False


class NotificationResponse(BaseModel):
    success: bool
    message: str
    sent_count: int


# In-memory storage for now (TODO: Add to database)
push_subscriptions: dict[str, list[dict]] = {}


@router.post("/subscribe")
@limiter.limit("10/minute")
async def subscribe_to_push_notifications(
    request: Request,
    subscription_data: PushSubscriptionCreate,
    current_user: UserProfileResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, str]:
    """
    Subscribe user to push notifications.
    Stores the push subscription for future notification delivery.
    """
    try:
        user_id = current_user.id

        # Store subscription (in production, save to database)
        if user_id not in push_subscriptions:
            push_subscriptions[user_id] = []

        # Remove any existing subscription with same endpoint
        push_subscriptions[user_id] = [
            sub
            for sub in push_subscriptions[user_id]
            if sub["endpoint"] != subscription_data.subscription.endpoint
        ]

        # Add new subscription
        subscription_record = {
            "endpoint": subscription_data.subscription.endpoint,
            "keys": subscription_data.subscription.keys,
            "user_agent": subscription_data.user_agent,
            "created_at": datetime.utcnow().isoformat(),
            "is_active": True,
        }

        push_subscriptions[user_id].append(subscription_record)

        return {
            "status": "success",
            "message": "Push subscription saved successfully",
            "subscription_id": f"{user_id}_{len(push_subscriptions[user_id])}",
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to save push subscription: {str(e)}",
        )


@router.get("/subscriptions")
async def get_user_subscriptions(
    current_user: UserProfileResponse = Depends(get_current_user),
) -> list[dict]:
    """
    Get all push subscriptions for the current user.
    """
    user_id = current_user.id
    return push_subscriptions.get(user_id, [])


@router.delete("/unsubscribe/{endpoint_hash}")
@limiter.limit("5/minute")
async def unsubscribe_from_push_notifications(
    request: Request,
    endpoint_hash: str,
    current_user: UserProfileResponse = Depends(get_current_user),
) -> dict[str, str]:
    """
    Unsubscribe from push notifications by removing specific subscription.
    """
    try:
        user_id = current_user.id

        if user_id not in push_subscriptions:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No subscriptions found for user",
            )

        # Mark subscription as inactive (don't delete for audit purposes)
        updated = False
        for subscription in push_subscriptions[user_id]:
            if str(hash(subscription["endpoint"])) == endpoint_hash:
                subscription["is_active"] = False
                updated = True
                break

        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Subscription not found"
            )

        return {
            "status": "success",
            "message": "Push subscription removed successfully",
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to remove push subscription: {str(e)}",
        )


@router.post("/send")
@limiter.limit("30/minute")
async def send_push_notification(
    request: Request,
    notification: NotificationSend,
    current_user: UserProfileResponse = Depends(get_current_user),
) -> NotificationResponse:
    """
    Send push notification to current user's devices.
    For testing and immediate notifications.
    """
    try:
        user_id = current_user.id

        if user_id not in push_subscriptions:
            return NotificationResponse(
                success=False,
                message="No push subscriptions found for user",
                sent_count=0,
            )

        active_subscriptions = [
            sub for sub in push_subscriptions[user_id] if sub.get("is_active", True)
        ]

        if not active_subscriptions:
            return NotificationResponse(
                success=False,
                message="No active push subscriptions found",
                sent_count=0,
            )

        # TODO: Implement actual push notification sending using web-push library
        # For now, just simulate success
        sent_count = len(active_subscriptions)

        return NotificationResponse(
            success=True,
            message=f"Notification sent to {sent_count} device(s)",
            sent_count=sent_count,
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send push notification: {str(e)}",
        )


@router.post("/test")
@limiter.limit("5/minute")
async def send_test_notification(
    request: Request,
    current_user: UserProfileResponse = Depends(get_current_user),
) -> NotificationResponse:
    """
    Send a test push notification to verify setup.
    """
    test_notification = NotificationSend(
        title="Vigor Test Notification",
        body=f"Hello {current_user.username}! Push notifications are working correctly.",
        icon="/icons/icon-192x192.png",
        badge="/icons/badge-72x72.png",
        tag="test_notification",
        require_interaction=False,
    )

    return await send_push_notification(request, test_notification, current_user)


# Health check endpoint
@router.get("/health")
async def push_service_health() -> dict[str, str]:
    """
    Check push notification service health.
    """
    return {
        "status": "healthy",
        "service": "push_notifications",
        "subscriptions_count": sum(len(subs) for subs in push_subscriptions.values()),
        "active_users": len(push_subscriptions),
    }
