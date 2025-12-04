"""
Google Gemini AI client for Vigor Functions
Single LLM provider for workout generation and AI coaching
"""

import asyncio
import json
import logging
from datetime import datetime
from typing import Dict, Any, List, Optional
import time

import google.generativeai as genai
from google.generativeai.types import HarmCategory, HarmBlockThreshold

from .config import get_settings

logger = logging.getLogger(__name__)


class GeminiAIClient:
    """Google Gemini Flash 2.0 client for AI operations"""

    def __init__(self):
        self.settings = get_settings()
        self.model_name = "gemini-2.0-flash"  # Gemini Flash 2.0 (stable)
        self.model = None
        self._initialize_client()

    def _initialize_client(self):
        """Initialize Gemini client"""
        try:
            api_key = self.settings.GOOGLE_AI_API_KEY
            if not api_key or api_key.startswith("your-"):
                logger.error(f"Gemini API key is not configured properly. Key starts with: {api_key[:10] if api_key else 'None'}...")
                return

            genai.configure(api_key=api_key)

            # Configure safety settings to be less restrictive for fitness content
            safety_settings = {
                HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_ONLY_HIGH,
                HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_ONLY_HIGH,
                HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_ONLY_HIGH,
                HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            }

            # Initialize the model
            self.model = genai.GenerativeModel(
                model_name=self.model_name,
                safety_settings=safety_settings
            )

            logger.info(f"Gemini AI client initialized with model: {self.model_name}, API key starts with: {api_key[:10]}...")

        except Exception as e:
            logger.error(f"Failed to initialize Gemini client: {type(e).__name__}: {str(e)}")
            self.model = None

    async def generate_workout(self, user_profile: Dict[str, Any], preferences: Dict[str, Any]) -> Dict[str, Any]:
        """Generate personalized workout using Gemini Flash 2.5"""
        try:
            start_time = time.time()

            # Build context from user profile
            fitness_level = user_profile.get("profile", {}).get("fitnessLevel", "beginner")
            goals = user_profile.get("profile", {}).get("goals", ["general fitness"])
            equipment = user_profile.get("profile", {}).get("equipment", "bodyweight")

            # Get preferences from request
            duration = preferences.get("durationMinutes", 45)
            focus_areas = preferences.get("focusAreas", [])
            difficulty = preferences.get("difficulty", "moderate")

            # Create detailed prompt
            prompt = self._build_workout_prompt(
                fitness_level=fitness_level,
                goals=goals,
                equipment=equipment,
                duration=duration,
                focus_areas=focus_areas,
                difficulty=difficulty
            )

            # Generate content
            response = await asyncio.to_thread(self.model.generate_content, prompt)

            # Parse response
            workout_data = self._parse_workout_response(response.text)

            # Add metadata
            workout_data["metadata"] = {
                "difficulty": difficulty,
                "estimatedDuration": duration,
                "equipmentNeeded": [equipment] if equipment != "bodyweight" else [],
                "aiProviderUsed": "gemini-flash-2.5",
                "generationTime": time.time() - start_time,
                "tags": focus_areas + goals
            }

            return workout_data

        except Exception as e:
            logger.error(f"Error generating workout: {str(e)}")
            raise Exception(f"Failed to generate workout: {str(e)}")

    async def generate_coach_response(self, user_message: str, conversation_history: List[Dict[str, Any]], user_context: Dict[str, Any]) -> str:
        """Generate AI coach response using conversation context"""
        try:
            start_time = time.time()

            # Build conversation context
            context_prompt = self._build_coach_context(user_context, conversation_history)

            # Create full prompt
            full_prompt = f"""{context_prompt}

User: {user_message}

AI Coach: """

            # Generate response
            response = await asyncio.to_thread(self.model.generate_content, full_prompt)

            # Clean up response
            coach_response = response.text.strip()

            # Log response time for monitoring
            response_time = (time.time() - start_time) * 1000  # milliseconds
            logger.info(f"Coach response generated in {response_time:.2f}ms")

            return coach_response

        except Exception as e:
            logger.error(f"Error generating coach response: {str(e)}")
            raise Exception(f"Failed to generate coach response: {str(e)}")

    def _build_workout_prompt(self, fitness_level: str, goals: List[str], equipment: str, duration: int, focus_areas: List[str], difficulty: str) -> str:
        """Build detailed workout generation prompt"""

        focus_text = f" with focus on {', '.join(focus_areas)}" if focus_areas else ""
        goals_text = ", ".join(goals) if goals else "general fitness"

        prompt = f"""
You are a certified personal trainer creating a personalized workout plan.

USER PROFILE:
- Fitness Level: {fitness_level}
- Goals: {goals_text}
- Available Equipment: {equipment}
- Workout Duration: {duration} minutes
- Difficulty: {difficulty}{focus_text}

REQUIREMENTS:
1. Create a {duration}-minute workout appropriate for {fitness_level} level
2. Use only {equipment} equipment
3. Include warm-up, main workout, and cool-down
4. Provide specific sets, reps, and rest times
5. Include brief instructions for each exercise
6. Ensure progression appropriate for {difficulty} difficulty

RESPONSE FORMAT (JSON):
{{
    "name": "Workout Name",
    "description": "Brief workout description",
    "exercises": [
        {{
            "name": "Exercise Name",
            "sets": 3,
            "reps": 12,
            "duration": null,
            "restTime": 60,
            "equipment": "{equipment}",
            "instructions": "Clear, safe instructions"
        }}
    ]
}}

Generate the workout plan as valid JSON only:
"""
        return prompt

    def _build_coach_context(self, user_context: Dict[str, Any], conversation_history: List[Dict[str, Any]]) -> str:
        """Build AI coach conversation context"""

        fitness_level = user_context.get("profile", {}).get("fitnessLevel", "beginner")
        goals = user_context.get("profile", {}).get("goals", [])

        context = f"""
You are Vigor AI Coach, a supportive and knowledgeable fitness coach. You help users achieve their fitness goals through personalized advice, motivation, and guidance.

USER PROFILE:
- Fitness Level: {fitness_level}
- Goals: {', '.join(goals) if goals else 'general fitness'}

PERSONALITY:
- Encouraging and positive
- Evidence-based advice
- Personalized recommendations
- Safety-first approach
- Motivational but realistic

CONVERSATION HISTORY:
"""

        # Add recent conversation context
        for message in conversation_history[-5:]:  # Last 5 messages
            role = "User" if message["role"] == "user" else "AI Coach"
            content = message["content"][:200] + "..." if len(message["content"]) > 200 else message["content"]
            context += f"{role}: {content}\n"

        context += "\nRespond as the AI Coach with helpful, personalized fitness advice:"

        return context

    def _parse_workout_response(self, response_text: str) -> Dict[str, Any]:
        """Parse and validate workout response from Gemini"""
        try:
            # Try to extract JSON from response
            # Sometimes the model includes extra text before/after JSON
            start_idx = response_text.find('{')
            end_idx = response_text.rfind('}') + 1

            if start_idx == -1 or end_idx == 0:
                raise ValueError("No JSON found in response")

            json_str = response_text[start_idx:end_idx]
            workout_data = json.loads(json_str)

            # Validate required fields
            if "name" not in workout_data:
                workout_data["name"] = "AI Generated Workout"
            if "description" not in workout_data:
                workout_data["description"] = "Personalized workout generated by AI"
            if "exercises" not in workout_data:
                raise ValueError("No exercises found in workout")

            # Validate exercises
            for i, exercise in enumerate(workout_data["exercises"]):
                if "name" not in exercise:
                    exercise["name"] = f"Exercise {i+1}"
                if "sets" not in exercise:
                    exercise["sets"] = 3
                if "reps" not in exercise and "duration" not in exercise:
                    exercise["reps"] = 12
                if "restTime" not in exercise:
                    exercise["restTime"] = 60
                if "equipment" not in exercise:
                    exercise["equipment"] = "bodyweight"
                if "instructions" not in exercise:
                    exercise["instructions"] = "Perform exercise as described"

            return workout_data

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON response: {str(e)}")
            # Return a fallback workout
            return self._create_fallback_workout()
        except Exception as e:
            logger.error(f"Error parsing workout response: {str(e)}")
            return self._create_fallback_workout()

    def _create_fallback_workout(self) -> Dict[str, Any]:
        """Create a basic fallback workout when AI generation fails"""
        return {
            "name": "Basic Bodyweight Workout",
            "description": "A simple bodyweight workout routine",
            "exercises": [
                {
                    "name": "Jumping Jacks",
                    "sets": 3,
                    "duration": 30,
                    "restTime": 30,
                    "equipment": "bodyweight",
                    "instructions": "Jump with feet apart while raising arms overhead"
                },
                {
                    "name": "Push-ups",
                    "sets": 3,
                    "reps": 10,
                    "restTime": 60,
                    "equipment": "bodyweight",
                    "instructions": "Lower chest to ground, push back up"
                },
                {
                    "name": "Bodyweight Squats",
                    "sets": 3,
                    "reps": 15,
                    "restTime": 60,
                    "equipment": "bodyweight",
                    "instructions": "Lower hips back and down, return to standing"
                },
                {
                    "name": "Plank",
                    "sets": 3,
                    "duration": 30,
                    "restTime": 30,
                    "equipment": "bodyweight",
                    "instructions": "Hold straight line from head to heels"
                }
            ]
        }

    async def health_check(self) -> bool:
        """Check Gemini API connectivity"""
        try:
            if not self.model:
                logger.error("Gemini health check failed: model not initialized")
                return False

            # Simple test generation
            test_prompt = "Say 'Hello' in one word."
            response = await asyncio.to_thread(self.model.generate_content, test_prompt)

            if response and hasattr(response, 'text'):
                return "hello" in response.text.lower()
            else:
                logger.error(f"Gemini health check failed: unexpected response format - {type(response)}")
                return False

        except Exception as e:
            logger.error(f"Gemini health check failed: {type(e).__name__}: {str(e)}")
            return False
