"""
Apple Push Notification Service (APNs) Client for Ghost Silent Push
Per PRD §3.4: "If not implemented as P0, Ghost dies after 3 days of non-use"

This module handles:
- Silent push notifications to wake iOS app
- Token management for APNs
- Push delivery with retry logic
"""

import asyncio
import json
import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

import httpx
import jwt

from .config import get_settings

logger = logging.getLogger(__name__)


class APNsClient:
    """Apple Push Notification Service client for Ghost silent pushes"""

    # APNs endpoints
    PRODUCTION_URL = "https://api.push.apple.com"
    SANDBOX_URL = "https://api.sandbox.push.apple.com"

    def __init__(self):
        self.settings = get_settings()
        self._token: Optional[str] = None
        self._token_timestamp: Optional[datetime] = None
        self._http_client: Optional[httpx.AsyncClient] = None

    @property
    def base_url(self) -> str:
        """Get APNs base URL based on environment"""
        is_sandbox = getattr(self.settings, 'APNS_SANDBOX', True)
        return self.SANDBOX_URL if is_sandbox else self.PRODUCTION_URL

    @property
    def bundle_id(self) -> str:
        """Get app bundle ID for APNs topic"""
        return getattr(self.settings, 'APNS_BUNDLE_ID', 'com.vigor.app')

    async def _get_http_client(self) -> httpx.AsyncClient:
        """Get or create HTTP/2 client for APNs"""
        if self._http_client is None:
            self._http_client = httpx.AsyncClient(
                http2=True,
                timeout=httpx.Timeout(30.0),
            )
        return self._http_client

    def _generate_token(self) -> str:
        """
        Generate JWT token for APNs authentication
        Token is valid for up to 1 hour
        """
        now = datetime.now(timezone.utc)

        # Check if we have a valid cached token (refresh after 50 mins)
        if self._token and self._token_timestamp:
            age = (now - self._token_timestamp).total_seconds()
            if age < 3000:  # 50 minutes
                return self._token

        # Get credentials from settings
        key_id = getattr(self.settings, 'APNS_KEY_ID', '')
        team_id = getattr(self.settings, 'APNS_TEAM_ID', '')
        private_key = getattr(self.settings, 'APNS_PRIVATE_KEY', '')

        if not all([key_id, team_id, private_key]):
            raise ValueError("APNs credentials not configured")

        # Create JWT token
        headers = {
            'alg': 'ES256',
            'kid': key_id
        }

        payload = {
            'iss': team_id,
            'iat': int(now.timestamp())
        }

        self._token = jwt.encode(
            payload,
            private_key,
            algorithm='ES256',
            headers=headers
        )
        self._token_timestamp = now

        return self._token

    async def send_silent_push(
        self,
        device_token: str,
        payload: Dict[str, Any],
        priority: int = 5,
        expiration: int = 0
    ) -> Dict[str, Any]:
        """
        Send a silent push notification to wake the iOS app

        Args:
            device_token: APNs device token
            payload: Push payload (content-available=1 for silent push)
            priority: 5 for normal, 10 for immediate
            expiration: Unix timestamp for expiration (0 = immediate)

        Returns:
            Dict with status and apns-id
        """
        try:
            # Build silent push payload
            apns_payload = {
                "aps": {
                    "content-available": 1  # Silent push flag
                }
            }

            # Add custom data
            if payload:
                apns_payload.update(payload)

            # Get auth token
            token = self._generate_token()

            # Build headers
            headers = {
                'authorization': f'bearer {token}',
                'apns-topic': self.bundle_id,
                'apns-push-type': 'background',  # Silent push type
                'apns-priority': str(priority),
                'apns-expiration': str(expiration)
            }

            # Send request
            url = f"{self.base_url}/3/device/{device_token}"
            client = await self._get_http_client()

            response = await client.post(
                url,
                headers=headers,
                content=json.dumps(apns_payload)
            )

            if response.status_code == 200:
                apns_id = response.headers.get('apns-id', '')
                logger.info(f"Silent push sent successfully: {apns_id}")
                return {
                    'status': 'sent',
                    'apns_id': apns_id,
                    'device_token': device_token[:16] + '...'  # Truncate for logging
                }
            else:
                error_body = response.text
                logger.error(f"APNs error {response.status_code}: {error_body}")
                return {
                    'status': 'error',
                    'code': response.status_code,
                    'error': error_body
                }

        except Exception as e:
            logger.error(f"Failed to send silent push: {e}")
            return {
                'status': 'error',
                'error': str(e)
            }

    async def send_batch_silent_push(
        self,
        targets: List[Dict[str, Any]],
        max_concurrent: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Send silent push to multiple devices with concurrency control

        Args:
            targets: List of {device_token, user_id, payload}
            max_concurrent: Max concurrent requests

        Returns:
            List of results for each target
        """
        semaphore = asyncio.Semaphore(max_concurrent)

        async def send_one(target: Dict[str, Any]) -> Dict[str, Any]:
            async with semaphore:
                result = await self.send_silent_push(
                    device_token=target['device_token'],
                    payload=target.get('payload', {})
                )
                result['user_id'] = target.get('user_id')
                return result

        tasks = [send_one(target) for target in targets]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Convert exceptions to error results
        processed_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                processed_results.append({
                    'status': 'error',
                    'error': str(result),
                    'user_id': targets[i].get('user_id')
                })
            else:
                processed_results.append(result)

        return processed_results

    async def close(self):
        """Close HTTP client"""
        if self._http_client:
            await self._http_client.aclose()
            self._http_client = None


class GhostPushPayloadBuilder:
    """Build Ghost-specific push payloads"""

    @staticmethod
    def morning_cycle() -> Dict[str, Any]:
        """Payload for morning Ghost cycle wake"""
        return {
            "ghost_action": "morning_cycle",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "actions": [
                "check_recovery",
                "update_schedule",
                "prepare_day"
            ]
        }

    @staticmethod
    def evening_cycle() -> Dict[str, Any]:
        """Payload for evening Ghost cycle"""
        return {
            "ghost_action": "evening_cycle",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "actions": [
                "log_day",
                "adjust_tomorrow",
                "calculate_trust"
            ]
        }

    @staticmethod
    def weekly_planning() -> Dict[str, Any]:
        """Payload for Sunday evening weekly planning"""
        return {
            "ghost_action": "weekly_planning",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "actions": [
                "propose_week",
                "show_receipt",
                "confirm_schedule"
            ]
        }

    @staticmethod
    def block_reminder(block_id: str, start_time: str) -> Dict[str, Any]:
        """Payload for upcoming block reminder"""
        return {
            "ghost_action": "block_reminder",
            "block_id": block_id,
            "start_time": start_time,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }

    @staticmethod
    def trust_update(delta: float, new_phase: str) -> Dict[str, Any]:
        """Payload for significant trust state changes"""
        return {
            "ghost_action": "trust_update",
            "delta": delta,
            "new_phase": new_phase,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }


# Global APNs client instance
_apns_client: Optional[APNsClient] = None


async def get_apns_client() -> APNsClient:
    """Get global APNs client instance"""
    global _apns_client
    if _apns_client is None:
        _apns_client = APNsClient()
    return _apns_client
