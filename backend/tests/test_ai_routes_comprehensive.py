"""
Comprehensive test suite for AI routes - Critical coverage improvement
"""

import json
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from api.schemas.ai import (
    ChatMessage,
    ChatResponse,
    GeneratedWorkoutPlan,
    WorkoutAnalysis,
    WorkoutRecommendationRequest,
)
from database.models import UserProfile
from main import app

client = TestClient(app)


class TestAIRoutes:
    """Test suite for AI API routes - addressing 49% coverage gap"""

    @pytest.fixture
    def auth_headers(self):
        """Mock authentication headers"""
        return {"Authorization": "Bearer test-token"}

    @pytest.fixture
    def sample_chat_message(self):
        """Sample chat message"""
        return {
            "message": "What's the best exercise for building chest muscles?"
        }

    @pytest.fixture
    def sample_workout_request(self):
        """Sample workout recommendation request"""
        return {
            "duration_minutes": 45,
            "equipment": "dumbbells",
            "focus_areas": ["chest", "triceps"],
            "goals": ["muscle_building"]
        }

    @pytest.fixture
    def mock_user_profile(self):
        """Mock user profile"""
        return UserProfile(
            id="test-user-123",
            username="testuser",
            email="test@example.com",
            fitness_level="intermediate",
            goals=["strength", "muscle_building"],
            equipment="dumbbells",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )

    def test_chat_endpoint_success(self, auth_headers, sample_chat_message):
        """Test successful chat interaction"""
        with patch("api.routes.ai.get_current_user") as mock_auth, \
             patch("api.services.ai.chat_with_ai_coach") as mock_chat:

            # Mock authentication
            mock_auth.return_value = MagicMock(id="test-user-123")

            # Mock chat service
            mock_chat.return_value = "Bench press and push-ups are excellent for chest development."

            response = client.post(
                "/ai/chat",
                json=sample_chat_message,
                headers=auth_headers
            )

            assert response.status_code == 200
            data = response.json()
            assert "response" in data
            assert "created_at" in data
            assert "bench press" in data["response"].lower()

    def test_chat_endpoint_unauthorized(self, sample_chat_message):
        """Test chat endpoint without authentication"""
        response = client.post("/ai/chat", json=sample_chat_message)

        assert response.status_code == 401

    def test_chat_endpoint_empty_message(self, auth_headers):
        """Test chat endpoint with empty message"""
        with patch("api.routes.ai.get_current_user") as mock_auth:
            mock_auth.return_value = MagicMock(id="test-user-123")

            response = client.post(
                "/ai/chat",
                json={"message": ""},
                headers=auth_headers
            )

            assert response.status_code == 422  # Validation error

    def test_chat_endpoint_message_too_long(self, auth_headers):
        """Test chat endpoint with message exceeding length limit"""
        with patch("api.routes.ai.get_current_user") as mock_auth:
            mock_auth.return_value = MagicMock(id="test-user-123")

            long_message = "x" * 1001  # Exceeds 1000 char limit

            response = client.post(
                "/ai/chat",
                json={"message": long_message},
                headers=auth_headers
            )

            assert response.status_code == 422  # Validation error

    def test_workout_generation_success(self, auth_headers, sample_workout_request, mock_user_profile):
        """Test successful workout generation"""
        mock_workout = GeneratedWorkoutPlan(
            name="Upper Body Strength",
            description="Focused chest and tricep workout",
            exercises=[
                {
                    "name": "Dumbbell Bench Press",
                    "sets": 3,
                    "reps": "8-10",
                    "rest": 120
                }
            ],
            duration_minutes=45,
            difficulty="intermediate",
            equipment_needed=["dumbbells"],
            notes="Focus on proper form"
        )

        with patch("api.routes.ai.get_current_user") as mock_auth, \
             patch("api.services.ai.generate_ai_workout_plan") as mock_generate:

            mock_auth.return_value = mock_user_profile
            mock_generate.return_value = mock_workout

            response = client.post(
                "/ai/workout/generate",
                json=sample_workout_request,
                headers=auth_headers
            )

            assert response.status_code == 200
            data = response.json()
            assert data["name"] == "Upper Body Strength"
            assert data["duration_minutes"] == 45
            assert len(data["exercises"]) == 1

    def test_workout_generation_invalid_duration(self, auth_headers):
        """Test workout generation with invalid duration"""
        with patch("api.routes.ai.get_current_user") as mock_auth:
            mock_auth.return_value = MagicMock(id="test-user-123")

            invalid_request = {
                "duration_minutes": 10,  # Below minimum of 15
                "equipment": "none"
            }

            response = client.post(
                "/ai/workout/generate",
                json=invalid_request,
                headers=auth_headers
            )

            assert response.status_code == 422  # Validation error

    def test_workout_generation_service_unavailable(self, auth_headers, sample_workout_request):
        """Test workout generation when AI service is unavailable"""
        with patch("api.routes.ai.get_current_user") as mock_auth, \
             patch("api.services.ai.generate_ai_workout_plan") as mock_generate:

            mock_auth.return_value = MagicMock(id="test-user-123")
            mock_generate.side_effect = Exception("AI service unavailable")

            response = client.post(
                "/ai/workout/generate",
                json=sample_workout_request,
                headers=auth_headers
            )

            assert response.status_code == 503  # Service unavailable

    def test_workout_analysis_success(self, auth_headers):
        """Test successful workout analysis"""
        workout_data = {
            "workout_log": [
                {
                    "exercise": "Bench Press",
                    "sets": 3,
                    "reps": [8, 8, 6],
                    "weight": 185
                }
            ],
            "duration_minutes": 60,
            "perceived_exertion": 7
        }

        mock_analysis = WorkoutAnalysis(
            overall_assessment="Good strength training session",
            strengths=["Consistent rep ranges", "Progressive overload"],
            areas_for_improvement=["Increase rest time", "Focus on form"],
            recommendations=["Add warm-up", "Track rest periods"],
            next_steps="Increase weight by 5lbs next session"
        )

        with patch("api.routes.ai.get_current_user") as mock_auth, \
             patch("api.services.ai.analyze_user_workout") as mock_analyze:

            mock_auth.return_value = MagicMock(id="test-user-123")
            mock_analyze.return_value = mock_analysis

            response = client.post(
                "/ai/workout/analyze",
                json=workout_data,
                headers=auth_headers
            )

            assert response.status_code == 200
            data = response.json()
            assert "overall_assessment" in data
            assert "strengths" in data
            assert "recommendations" in data

    def test_chat_history_retrieval(self, auth_headers):
        """Test retrieving chat conversation history"""
        mock_history = [
            {
                "message": "What's the best chest exercise?",
                "response": "Bench press is excellent for chest development.",
                "timestamp": datetime.utcnow().isoformat()
            }
        ]

        with patch("api.routes.ai.get_current_user") as mock_auth, \
             patch("api.services.ai.get_conversation_history") as mock_history_service:

            mock_auth.return_value = MagicMock(id="test-user-123")
            mock_history_service.return_value = mock_history

            response = client.get("/ai/chat/history", headers=auth_headers)

            assert response.status_code == 200
            data = response.json()
            assert len(data) == 1
            assert "message" in data[0]
            assert "response" in data[0]

    def test_ai_status_endpoint(self, auth_headers):
        """Test AI service status endpoint"""
        with patch("api.routes.ai.get_current_user") as mock_auth:
            mock_auth.return_value = MagicMock(id="test-user-123")

            with patch("core.ai.check_ai_service_health") as mock_health:
                mock_health.return_value = {
                    "status": "healthy",
                    "providers": {
                        "openai": {"available": True, "latency_ms": 250},
                        "gemini": {"available": True, "latency_ms": 300}
                    }
                }

                response = client.get("/ai/status", headers=auth_headers)

                assert response.status_code == 200
                data = response.json()
                assert data["status"] == "healthy"
                assert "providers" in data

    def test_rate_limiting(self, auth_headers, sample_chat_message):
        """Test API rate limiting"""
        with patch("api.routes.ai.get_current_user") as mock_auth:
            mock_auth.return_value = MagicMock(id="test-user-123")

            # Simulate rate limit exceeded
            with patch("api.routes.ai.check_rate_limit", return_value=False):
                response = client.post(
                    "/ai/chat",
                    json=sample_chat_message,
                    headers=auth_headers
                )

                assert response.status_code == 429  # Too Many Requests

    def test_input_sanitization(self, auth_headers):
        """Test input sanitization for security"""
        malicious_input = {
            "message": "<script>alert('xss')</script>What's a good workout?"
        }

        with patch("api.routes.ai.get_current_user") as mock_auth, \
             patch("api.services.ai.chat_with_ai_coach") as mock_chat:

            mock_auth.return_value = MagicMock(id="test-user-123")
            mock_chat.return_value = "Here's a safe workout recommendation."

            response = client.post(
                "/ai/chat",
                json=malicious_input,
                headers=auth_headers
            )

            # Should process but sanitize input
            assert response.status_code == 200
            # Verify input was sanitized before processing
            mock_chat.assert_called_once()
            call_args = mock_chat.call_args[1]  # Get keyword arguments
            assert "<script>" not in call_args.get("message", "")

    def test_usage_tracking(self, auth_headers, sample_chat_message):
        """Test that API usage is properly tracked"""
        with patch("api.routes.ai.get_current_user") as mock_auth, \
             patch("api.services.ai.chat_with_ai_coach") as mock_chat, \
             patch("api.routes.ai.track_api_usage") as mock_track:

            mock_auth.return_value = MagicMock(id="test-user-123")
            mock_chat.return_value = "Response"

            response = client.post(
                "/ai/chat",
                json=sample_chat_message,
                headers=auth_headers
            )

            assert response.status_code == 200
            mock_track.assert_called_once()

    def test_error_handling_and_logging(self, auth_headers, sample_chat_message):
        """Test proper error handling and logging"""
        with patch("api.routes.ai.get_current_user") as mock_auth, \
             patch("api.services.ai.chat_with_ai_coach") as mock_chat, \
             patch("api.routes.ai.logger") as mock_logger:

            mock_auth.return_value = MagicMock(id="test-user-123")
            mock_chat.side_effect = Exception("Unexpected error")

            response = client.post(
                "/ai/chat",
                json=sample_chat_message,
                headers=auth_headers
            )

            # Should return 500 for unexpected errors
            assert response.status_code == 500

            # Should log the error
            mock_logger.error.assert_called_once()
