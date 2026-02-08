"""
Device Management Blueprint — iOS-facing endpoints
Endpoints: devices/register, devices/push-token

These endpoints match the paths called by iOS ``VigorAPIClient.swift``.
"""

import logging
import re
from datetime import datetime, timezone

import azure.functions as func

from shared.auth import get_current_user_from_token
from shared.helpers import error_response, success_response

logger = logging.getLogger(__name__)

devices_bp = func.Blueprint()

_DEVICE_TOKEN_RE = re.compile(r"^[0-9a-fA-F]{64}$")


@devices_bp.route(
    route="devices/register", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def register_device(req: func.HttpRequest) -> func.HttpResponse:
    """Register a device — iOS ``registerDevice``

    Stores device metadata on the user document so the backend knows what
    capabilities the client has (Watch pairing, push support, etc.).
    """
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        try:
            body = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        if not body or "deviceId" not in body:
            return error_response(
                "Missing required field: deviceId",
                status_code=400,
                code="MISSING_FIELD",
            )

        client = await get_global_client()
        user_id = current_user["email"]

        user_profile = await client.get_user_profile(user_id)
        if not user_profile:
            user_profile = {"id": user_id, "email": user_id}

        # Update device info on user document
        devices = user_profile.get("devices", [])
        device_entry = {
            "deviceId": body["deviceId"],
            "deviceType": body.get("deviceType", "iphone"),
            "osVersion": body.get("osVersion", ""),
            "appVersion": body.get("appVersion", ""),
            "capabilities": body.get("capabilities", []),
            "isPrimary": body.get("isPrimary", False),
            "registeredAt": datetime.now(timezone.utc).isoformat(),
        }

        # Replace existing entry for same deviceId or append
        devices = [d for d in devices if d.get("deviceId") != body["deviceId"]]
        devices.append(device_entry)
        user_profile["devices"] = devices

        # Store push token if provided
        if body.get("pushToken"):
            user_profile["apns_device_token"] = body["pushToken"]
            user_profile["apns_registered_at"] = datetime.now(
                timezone.utc
            ).isoformat()

        await client.upsert_document("users", user_profile)

        logger.info(f"Device registered for {user_id}: {body['deviceId'][:8]}...")
        return success_response({"status": "registered", "deviceId": body["deviceId"]})

    except Exception as e:
        logger.error(f"Device registration error: {str(e)}")
        return error_response("Internal server error", status_code=500)


@devices_bp.route(
    route="devices/push-token", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS
)
async def register_push_token(req: func.HttpRequest) -> func.HttpResponse:
    """Register push token — iOS ``registerPushToken``

    Delegates to the same storage logic as ``ghost/device-token``.
    """
    try:
        from shared.cosmos_db import get_global_client

        current_user = await get_current_user_from_token(req)
        if not current_user:
            return error_response("Unauthorized", status_code=401, code="UNAUTHORIZED")

        try:
            body = req.get_json()
        except ValueError:
            return error_response("Invalid JSON", status_code=400, code="INVALID_JSON")

        token = (body or {}).get("token", "")
        if not token or not _DEVICE_TOKEN_RE.match(token):
            return error_response(
                "token must be a 64-character hex string",
                status_code=400,
                code="INVALID_TOKEN",
            )

        client = await get_global_client()
        user_id = current_user["email"]

        user_profile = await client.get_user_profile(user_id)
        if not user_profile:
            user_profile = {"id": user_id, "email": user_id}

        user_profile["apns_device_token"] = token
        user_profile["apns_platform"] = "ios"
        user_profile["apns_registered_at"] = datetime.now(timezone.utc).isoformat()
        await client.upsert_document("users", user_profile)

        logger.info(f"Push token registered for {user_id}")
        return success_response(
            {"status": "registered", "token_prefix": token[:8] + "..."}
        )

    except Exception as e:
        logger.error(f"Push token registration error: {str(e)}")
        return error_response("Internal server error", status_code=500)
