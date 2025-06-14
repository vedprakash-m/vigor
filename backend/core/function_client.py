"""
Azure Function client for the Vigor backend
This module handles the communication with the Azure Functions
"""

import json
import logging
import os
from typing import Any, Dict, List, Optional

import httpx

from core.azure_auth import AzureServiceAuth
from core.config import get_settings
from core.function_performance import FunctionPerformanceMonitor

settings = get_settings()

# Default function base URL with environment variable override
FUNCTIONS_API_URL = os.environ.get(
    "FUNCTIONS_API_URL", "https://vigor-ai-functions.azurewebsites.net/api"
)

# Azure Service Auth client for getting function keys
azure_auth = AzureServiceAuth()

logger = logging.getLogger(__name__)

# Create performance monitor
perf_monitor = FunctionPerformanceMonitor()


class FunctionsClient:
    """Client for interacting with Azure Functions."""

    def __init__(self, base_url: Optional[str] = None):
        """Initialize the client."""
        self.base_url = base_url or FUNCTIONS_API_URL
        # Remove trailing slash if present
        if self.base_url.endswith("/"):
            self.base_url = self.base_url[:-1]

    async def _call_function(
        self, endpoint: str, payload: Dict[str, Any], timeout: int = 30
    ) -> Dict[str, Any]:
        """Call an Azure Function endpoint."""
        url = f"{self.base_url}/{endpoint}"

        # Get function key using Azure managed identity
        function_name = endpoint.split("/")[0] if "/" in endpoint else endpoint
        function_key = await azure_auth.get_function_key(function_name)

        # Add code query parameter with function key if available
        if function_key:
            url += f"?code={function_key}"

        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                headers = {
                    "Content-Type": "application/json",
                }

                logger.debug(f"Calling function: {endpoint}")
                response = await client.post(url, json=payload, headers=headers)

                # Check for successful response
                response.raise_for_status()
                return response.json()

        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error calling {endpoint}: {str(e)}")
            try:
                error_body = e.response.json()
                logger.error(f"Error response: {error_body}")
            except Exception:
                pass
            raise RuntimeError(
                f"Function call to {endpoint} failed with status {e.response.status_code}"
            )
        except httpx.TimeoutException:
            logger.error(f"Timeout calling {endpoint}")
            raise RuntimeError(
                f"Function call to {endpoint} timed out after {timeout} seconds"
            )
        except Exception as e:
            logger.error(f"Error calling {endpoint}: {str(e)}")
            raise RuntimeError(f"Function call to {endpoint} failed: {str(e)}")

    async def generate_workout_plan(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: Optional[str] = None,
        duration_minutes: int = 45,
        focus_areas: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """Call the GenerateWorkout function."""
        payload = {
            "fitness_level": fitness_level,
            "goals": goals,
            "equipment": equipment,
            "duration_minutes": duration_minutes,
            "focus_areas": focus_areas,
        }

        # Use the performance monitor to track function calls
        return await perf_monitor.monitor_call(
            "generate-workout",
            self._call_function,
            "generate-workout",
            payload,
            timeout=30,
        )

    async def analyze_workout(
        self,
        workout_data: Dict[str, Any],
        user_fitness_level: str,
        previous_workouts: Optional[List[Dict[str, Any]]] = None,
    ) -> Dict[str, Any]:
        """Call the AnalyzeWorkout function."""
        payload = {
            "workout_data": workout_data,
            "user_fitness_level": user_fitness_level,
            "previous_workouts": previous_workouts,
        }

        # Use the performance monitor to track function calls
        return await perf_monitor.monitor_call(
            "analyze-workout",
            self._call_function,
            "analyze-workout",
            payload,
            timeout=30,
        )

    async def coach_chat(
        self,
        message: str,
        fitness_level: str,
        goals: List[str],
        conversation_history: Optional[List[Dict[str, str]]] = None,
    ) -> str:
        """Call the CoachChat function."""
        payload = {
            "message": message,
            "fitness_level": fitness_level,
            "goals": goals,
            "conversation_history": conversation_history,
        }

        # Use the performance monitor to track function calls
        response = await perf_monitor.monitor_call(
            "coach-chat", self._call_function, "coach-chat", payload, timeout=15
        )
        return response.get("response", "Sorry, I couldn't process your message.")
