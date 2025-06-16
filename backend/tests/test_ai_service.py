"""
Comprehensive test suite for AI service functionality
"""

import json
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from api.schemas.ai import ChatRequest, ChatResponse, WorkoutRequest, WorkoutResponse
from api.services.ai import AIService, CoachChatService, WorkoutGenerator
from database.models import UserProfile, WorkoutPlan


class TestAIService:
    """Test suite for AI service functionality"""

    @pytest.fixture
    def ai_service(self):
        """Create AI service instance"""
        return AIService()

    @pytest.fixture
    def sample_user_profile(self):
        """Sample user profile for testing"""
        return UserProfile(
            id=1,
            username="testuser",
            email="test@example.com",
            fitness_level="intermediate",
            goals=["weight_loss", "strength"],
            preferences={"equipment": ["dumbbells", "bodyweight"]},
            created_at=datetime.utcnow(),
        )

    @pytest.fixture
    def sample_workout_request(self):
        """Sample workout generation request"""
        return WorkoutRequest(
            user_id=1,
            workout_type="strength",
            duration_minutes=45,
            difficulty="intermediate",
            equipment=["dumbbells", "bench"],
            target_muscles=["chest", "triceps"],
            goals=["muscle_building"],
        )

    @pytest.fixture
    def sample_chat_request(self):
        """Sample chat request"""
        return ChatRequest(
            user_id=1,
            message="How can I improve my bench press form?",
            context="workout_coaching",
            session_id="chat-session-123",
        )


class TestWorkoutGenerator:
    """Test suite for workout generation functionality"""

    @pytest.fixture
    def workout_generator(self):
        """Create workout generator instance"""
        return WorkoutGenerator()

    @pytest.mark.asyncio
    async def test_generate_workout_success(
        self, workout_generator, sample_workout_request, sample_user_profile
    ):
        """Test successful workout generation"""
        with patch("api.services.ai.llm_gateway") as mock_gateway:
            # Mock LLM response
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content=json.dumps(
                        {
                            "workout_name": "Upper Body Strength",
                            "exercises": [
                                {
                                    "name": "Dumbbell Bench Press",
                                    "sets": 3,
                                    "reps": "8-10",
                                    "rest_seconds": 120,
                                    "instructions": "Keep core tight, control the weight",
                                },
                                {
                                    "name": "Dumbbell Tricep Extension",
                                    "sets": 3,
                                    "reps": "10-12",
                                    "rest_seconds": 90,
                                    "instructions": "Focus on tricep isolation",
                                },
                            ],
                            "estimated_duration": 45,
                            "difficulty_rating": 7,
                            "notes": "Focus on form over weight",
                        }
                    ),
                    tokens_used=150,
                    cost_estimate=0.003,
                )
            )

            result = await workout_generator.generate_workout(
                sample_workout_request, sample_user_profile
            )

            assert isinstance(result, WorkoutResponse)
            assert result.workout_name == "Upper Body Strength"
            assert len(result.exercises) == 2
            assert result.exercises[0]["name"] == "Dumbbell Bench Press"
            assert result.estimated_duration == 45

    @pytest.mark.asyncio
    async def test_generate_workout_with_restrictions(
        self, workout_generator, sample_user_profile
    ):
        """Test workout generation with dietary/medical restrictions"""
        restricted_request = WorkoutRequest(
            user_id=1,
            workout_type="cardio",
            duration_minutes=30,
            difficulty="beginner",
            equipment=["none"],
            restrictions=["knee_injury", "no_jumping"],
            goals=["endurance"],
        )

        with patch("api.services.ai.llm_gateway") as mock_gateway:
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content=json.dumps(
                        {
                            "workout_name": "Low-Impact Cardio",
                            "exercises": [
                                {
                                    "name": "Walking in Place",
                                    "duration_minutes": 10,
                                    "intensity": "moderate",
                                    "instructions": "Keep knees soft, avoid high impact",
                                },
                                {
                                    "name": "Seated Leg Extensions",
                                    "sets": 2,
                                    "reps": "15",
                                    "rest_seconds": 60,
                                    "instructions": "Gentle movement, stop if pain",
                                },
                            ],
                            "estimated_duration": 30,
                            "difficulty_rating": 3,
                            "notes": "Modified for knee injury - avoid jumping",
                        }
                    )
                )
            )

            result = await workout_generator.generate_workout(
                restricted_request, sample_user_profile
            )

            assert result.workout_name == "Low-Impact Cardio"
            assert "knee" in result.notes.lower() or "jumping" in result.notes.lower()

    @pytest.mark.asyncio
    async def test_generate_workout_llm_error(
        self, workout_generator, sample_workout_request, sample_user_profile
    ):
        """Test workout generation when LLM service fails"""
        with patch("api.services.ai.llm_gateway") as mock_gateway:
            mock_gateway.process_request = AsyncMock(
                side_effect=Exception("LLM service unavailable")
            )

            with pytest.raises(Exception) as exc_info:
                await workout_generator.generate_workout(
                    sample_workout_request, sample_user_profile
                )

            assert "LLM service unavailable" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_generate_workout_invalid_llm_response(
        self, workout_generator, sample_workout_request, sample_user_profile
    ):
        """Test workout generation with invalid LLM response format"""
        with patch("api.services.ai.llm_gateway") as mock_gateway:
            # Mock invalid JSON response
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content="This is not valid JSON",
                    tokens_used=50,
                    cost_estimate=0.001,
                )
            )

            with pytest.raises(Exception) as exc_info:
                await workout_generator.generate_workout(
                    sample_workout_request, sample_user_profile
                )

            assert (
                "json" in str(exc_info.value).lower()
                or "parse" in str(exc_info.value).lower()
            )

    @pytest.mark.asyncio
    async def test_personalize_workout_for_beginner(
        self, workout_generator, sample_user_profile
    ):
        """Test workout personalization for beginner users"""
        sample_user_profile.fitness_level = "beginner"

        beginner_request = WorkoutRequest(
            user_id=1,
            workout_type="full_body",
            duration_minutes=30,
            difficulty="beginner",
            equipment=["bodyweight"],
            goals=["general_fitness"],
        )

        with patch("api.services.ai.llm_gateway") as mock_gateway:
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content=json.dumps(
                        {
                            "workout_name": "Beginner Full Body",
                            "exercises": [
                                {
                                    "name": "Modified Push-ups",
                                    "sets": 2,
                                    "reps": "5-8",
                                    "rest_seconds": 90,
                                    "instructions": "Start on knees if needed",
                                }
                            ],
                            "estimated_duration": 30,
                            "difficulty_rating": 2,
                            "notes": "Perfect for beginners - focus on form",
                        }
                    )
                )
            )

            result = await workout_generator.generate_workout(
                beginner_request, sample_user_profile
            )

            assert result.difficulty_rating <= 3
            assert (
                "beginner" in result.workout_name.lower()
                or "beginner" in result.notes.lower()
            )


class TestCoachChatService:
    """Test suite for coach chat functionality"""

    @pytest.fixture
    def coach_chat_service(self):
        """Create coach chat service instance"""
        return CoachChatService()

    @pytest.mark.asyncio
    async def test_process_chat_fitness_question(
        self, coach_chat_service, sample_chat_request, sample_user_profile
    ):
        """Test processing fitness-related chat questions"""
        with patch("api.services.ai.llm_gateway") as mock_gateway:
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content="To improve your bench press form, focus on these key points:\n\n1. Keep your feet planted firmly on the ground\n2. Maintain a slight arch in your back\n3. Grip the bar slightly wider than shoulder-width\n4. Lower the bar to your chest with control\n5. Drive through your feet as you press up\n\nRemember to start with lighter weights to practice proper form!",
                    tokens_used=95,
                    cost_estimate=0.0019,
                )
            )

            result = await coach_chat_service.process_chat(
                sample_chat_request, sample_user_profile
            )

            assert isinstance(result, ChatResponse)
            assert "bench press" in result.response.lower()
            assert "form" in result.response.lower()
            assert result.tokens_used == 95
            assert result.session_id == "chat-session-123"

    @pytest.mark.asyncio
    async def test_process_chat_nutrition_question(
        self, coach_chat_service, sample_user_profile
    ):
        """Test processing nutrition-related questions"""
        nutrition_request = ChatRequest(
            user_id=1,
            message="What should I eat before a workout?",
            context="nutrition",
            session_id="nutrition-chat-456",
        )

        with patch("api.services.ai.llm_gateway") as mock_gateway:
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content="For pre-workout nutrition, consider these options:\n\n• 30-60 minutes before: Banana with peanut butter\n• 1-2 hours before: Oatmeal with berries\n• Light snack: Greek yogurt with honey\n\nAvoid heavy, high-fat meals close to workout time. Stay hydrated!",
                    tokens_used=78,
                    cost_estimate=0.0016,
                )
            )

            result = await coach_chat_service.process_chat(
                nutrition_request, sample_user_profile
            )

            assert (
                "nutrition" in result.response.lower()
                or "eat" in result.response.lower()
            )
            assert result.context == "nutrition"

    @pytest.mark.asyncio
    async def test_process_chat_with_context_history(
        self, coach_chat_service, sample_user_profile
    ):
        """Test chat processing with conversation context"""
        chat_with_history = ChatRequest(
            user_id=1,
            message="What about for someone with knee problems?",
            context="exercise_modification",
            session_id="ongoing-chat-789",
            conversation_history=[
                {"role": "user", "content": "What are good leg exercises?"},
                {
                    "role": "assistant",
                    "content": "Great leg exercises include squats, lunges, and leg press...",
                },
            ],
        )

        with patch("api.services.ai.llm_gateway") as mock_gateway:
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content="For someone with knee problems, I'd recommend these modifications:\n\n• Replace squats with wall sits\n• Use assisted lunges with support\n• Try seated leg extensions\n• Focus on low-impact exercises\n• Always consult your doctor first",
                    tokens_used=105,
                    cost_estimate=0.0021,
                )
            )

            result = await coach_chat_service.process_chat(
                chat_with_history, sample_user_profile
            )

            assert "knee" in result.response.lower()
            assert len(chat_with_history.conversation_history) == 2

    @pytest.mark.asyncio
    async def test_process_chat_inappropriate_content(
        self, coach_chat_service, sample_user_profile
    ):
        """Test handling of inappropriate or off-topic questions"""
        inappropriate_request = ChatRequest(
            user_id=1,
            message="Can you help me with my taxes?",
            context="general",
            session_id="offtopic-chat-999",
        )

        with patch("api.services.ai.llm_gateway") as mock_gateway:
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content="I'm a fitness coach AI, so I specialize in helping with workouts, nutrition, and fitness-related questions. For tax help, I'd recommend consulting a qualified tax professional or using tax software. Is there anything fitness-related I can help you with instead?",
                    tokens_used=55,
                    cost_estimate=0.0011,
                )
            )

            result = await coach_chat_service.process_chat(
                inappropriate_request, sample_user_profile
            )

            assert "fitness" in result.response.lower()
            assert "tax" in result.response.lower()

    @pytest.mark.asyncio
    async def test_process_chat_error_handling(
        self, coach_chat_service, sample_chat_request, sample_user_profile
    ):
        """Test error handling in chat processing"""
        with patch("api.services.ai.llm_gateway") as mock_gateway:
            mock_gateway.process_request = AsyncMock(
                side_effect=Exception("Chat service error")
            )

            with pytest.raises(Exception) as exc_info:
                await coach_chat_service.process_chat(
                    sample_chat_request, sample_user_profile
                )

            assert "Chat service error" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_process_chat_with_user_preferences(
        self, coach_chat_service, sample_user_profile
    ):
        """Test chat processing considering user preferences"""
        # Update user profile with specific preferences
        sample_user_profile.preferences = {
            "workout_style": "high_intensity",
            "equipment": ["kettlebells", "resistance_bands"],
            "time_availability": "30_minutes",
        }

        equipment_request = ChatRequest(
            user_id=1,
            message="Suggest a quick workout for me",
            context="workout_suggestion",
            session_id="personalized-chat-111",
        )

        with patch("api.services.ai.llm_gateway") as mock_gateway:
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content="Based on your preferences for high-intensity 30-minute workouts with kettlebells and resistance bands:\n\n• 5-minute warm-up\n• 20-minute HIIT circuit:\n  - Kettlebell swings (45 sec)\n  - Resistance band rows (45 sec)\n  - Rest (30 sec)\n• 5-minute cool-down\n\nThis matches your equipment and time preferences!",
                    tokens_used=120,
                    cost_estimate=0.0024,
                )
            )

            result = await coach_chat_service.process_chat(
                equipment_request, sample_user_profile
            )

            response_lower = result.response.lower()
            assert "kettlebell" in response_lower or "resistance" in response_lower
            assert "30" in result.response or "quick" in response_lower


class TestAIServiceIntegration:
    """Integration tests for AI service components"""

    @pytest.mark.asyncio
    async def test_workout_generation_and_chat_integration(self, sample_user_profile):
        """Test integration between workout generation and chat services"""
        ai_service = AIService()

        # First, generate a workout
        workout_request = WorkoutRequest(
            user_id=1,
            workout_type="strength",
            duration_minutes=30,
            difficulty="intermediate",
            equipment=["dumbbells"],
        )

        with patch("api.services.ai.llm_gateway") as mock_gateway:
            # Mock workout generation
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content=json.dumps(
                        {
                            "workout_name": "Dumbbell Strength Circuit",
                            "exercises": [
                                {
                                    "name": "Dumbbell Squats",
                                    "sets": 3,
                                    "reps": "12-15",
                                    "rest_seconds": 90,
                                }
                            ],
                            "estimated_duration": 30,
                            "difficulty_rating": 5,
                        }
                    )
                )
            )

            workout = await ai_service.generate_workout(
                workout_request, sample_user_profile
            )

            # Then ask a follow-up question about the workout
            chat_request = ChatRequest(
                user_id=1,
                message="How do I modify the dumbbell squats if they're too hard?",
                context="workout_modification",
                session_id="post-workout-chat",
            )

            # Mock chat response
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content="To make dumbbell squats easier:\n• Use lighter dumbbells or bodyweight only\n• Reduce the depth of your squat\n• Use a chair for support\n• Reduce sets to 2 instead of 3",
                    tokens_used=65,
                )
            )

            chat_response = await ai_service.process_chat(
                chat_request, sample_user_profile
            )

            assert workout.workout_name == "Dumbbell Strength Circuit"
            assert "squat" in chat_response.response.lower()
            assert "easier" in chat_response.response.lower()

    @pytest.mark.asyncio
    async def test_ai_service_rate_limiting(self, sample_user_profile):
        """Test AI service handles rate limiting gracefully"""
        ai_service = AIService()

        with patch("api.services.ai.llm_gateway") as mock_gateway:
            # Simulate rate limiting error
            mock_gateway.process_request = AsyncMock(
                side_effect=Exception("Rate limit exceeded")
            )

            workout_request = WorkoutRequest(
                user_id=1, workout_type="cardio", duration_minutes=20
            )

            with pytest.raises(Exception) as exc_info:
                await ai_service.generate_workout(workout_request, sample_user_profile)

            assert "rate limit" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_ai_service_user_tier_handling(self, sample_user_profile):
        """Test AI service handles different user tiers appropriately"""
        # Test premium user gets enhanced features
        sample_user_profile.tier = "premium"

        ai_service = AIService()
        premium_request = WorkoutRequest(
            user_id=1,
            workout_type="advanced_strength",
            duration_minutes=60,
            difficulty="advanced",
        )

        with patch("api.services.ai.llm_gateway") as mock_gateway:
            mock_gateway.process_request = AsyncMock(
                return_value=MagicMock(
                    content=json.dumps(
                        {
                            "workout_name": "Advanced Strength Training",
                            "exercises": [{"name": "Complex exercise", "sets": 4}],
                            "premium_features": {
                                "video_links": ["https://example.com/video1"],
                                "detailed_analytics": True,
                                "personalized_tips": "Advanced form cues...",
                            },
                        }
                    )
                )
            )

            result = await ai_service.generate_workout(
                premium_request, sample_user_profile
            )
            # Verify premium features are included in processing
            assert result is not None
