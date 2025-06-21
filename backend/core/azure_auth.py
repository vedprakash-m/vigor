"""
Authentication utilities for Azure services
Handles authentication between the App Service and Function App
"""

import os
import time
from typing import Dict, List, Optional, Union

import httpx
from azure.identity import DefaultAzureCredential


class AzureServiceAuth:
    """Authentication utilities for Azure services."""

    def __init__(self):
        """Initialize the auth client."""
        # Check if running in Azure
        self.is_azure_environment = os.environ.get("WEBSITE_SITE_NAME") is not None

        self.function_app_name = os.environ.get(
            "FUNCTION_APP_NAME", "vigor-ai-functions"
        )
        self.resource_group = os.environ.get("RESOURCE_GROUP", "vigor-rg")
        self.subscription_id = os.environ.get("AZURE_SUBSCRIPTION_ID")

        # Cache for Function keys
        self._function_key_cache: Dict[str, Dict[str, str]] = {}
        self._function_key_expiry: Dict[str, float] = {}
        self._cache_duration = 3600  # 1 hour

    async def get_function_key(
        self, function_name: Optional[str] = None
    ) -> Optional[str]:
        """
        Get function key for a specific function or the default host key.
        Uses Azure managed identity when running in Azure, or falls back to environment variable.
        """
        # Check cache first
        cache_key = function_name or "_host_"
        current_time = time.time()

        if (
            cache_key in self._function_key_cache
            and current_time < self._function_key_expiry.get(cache_key, 0)
        ):
            return self._function_key_cache[cache_key].get("default")

        # If running locally, get from environment
        if not self.is_azure_environment:
            return os.environ.get("FUNCTIONS_API_KEY")

        try:
            # Using Azure managed identity to get function keys
            credential = DefaultAzureCredential()
            access_token = credential.get_token("https://management.azure.com/.default")

            management_api_version = "2022-03-01"

            if function_name:
                # Get key for specific function
                url = (
                    f"https://management.azure.com/subscriptions/{self.subscription_id}/resourceGroups/"
                    f"{self.resource_group}/providers/Microsoft.Web/sites/{self.function_app_name}/"
                    f"functions/{function_name}/keys/default?api-version={management_api_version}"
                )
            else:
                # Get host key
                url = (
                    f"https://management.azure.com/subscriptions/{self.subscription_id}/resourceGroups/"
                    f"{self.resource_group}/providers/Microsoft.Web/sites/{self.function_app_name}/"
                    f"host/default/listkeys?api-version={management_api_version}"
                )

            headers = {
                "Authorization": f"Bearer {access_token.token}",
                "Content-Type": "application/json",
            }

            async with httpx.AsyncClient() as client:
                response = await client.post(url, headers=headers)
                response.raise_for_status()
                data = response.json()

                # Store in cache
                self._function_key_cache[cache_key] = data.get("value", data)
                self._function_key_expiry[cache_key] = (
                    current_time + self._cache_duration
                )

                # Return default key
                if function_name:
                    return data.get("value")
                return data.get("default")

        except Exception as e:
            import logging

            logging.error(f"Error getting function key: {str(e)}")
            return None
