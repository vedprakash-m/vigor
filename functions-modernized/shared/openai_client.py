"""
Azure OpenAI client for Vigor Functions
Single LLM provider using gpt-4o-mini for workout generation and AI coaching
Deployed in vigor-rg alongside other Azure resources
"""

import json
import logging
from typing import Dict, Any, List, Optional
import time

from openai import AsyncAzureOpenAI

from .config import get_settings

logger = logging.getLogger(__name__)


class OpenAIClient:
    """Azure OpenAI gpt-4o-mini client for AI operations"""

    def __init__(self):
        self.settings = get_settings()
        self.deployment = self.settings.AZURE_OPENAI_DEPLOYMENT or "gpt-4o-mini"
        self.client: Optional[AsyncAzureOpenAI] = None
        self._initialize_client()

    def _initialize_client(self):
        """Initialize Azure OpenAI client"""
        try:
            endpoint = self.settings.AZURE_OPENAI_ENDPOINT
            api_key = self.settings.AZURE_OPENAI_API_KEY

            # Validate configuration
            if not endpoint or endpoint.startswith("https://your-"):
                logger.warning("Azure OpenAI endpoint is not configured properly")
                return

            if not api_key or api_key.startswith("your-") or api_key.startswith("sk-"):
                logger.warning("Azure OpenAI API key is not configured properly")
                return

            self.client = AsyncAzureOpenAI(
                azure_endpoint=endpoint,
                api_key=api_key,
                api_version="2024-02-01"
            )
            logger.info(f"Azure OpenAI client initialized with deployment: {self.deployment}")

        except Exception as e:
            logger.error(f"Failed to initialize Azure OpenAI client: {type(e).__name__}: {str(e)}")
            self.client = None

    async def generate_workout(
        self,
        user_profile: Dict[str, Any],
        preferences: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Generate personalized workout using OpenAI gpt-4o-mini"""
        try:
            start_time = time.time()

            if not self.client:
                raise ValueError("OpenAI client not initialized")

            # Build context from user profile
            profile_data = user_profile.get("profile", {})
            fitness_level = profile_data.get("fitnessLevel", "beginner")
            goals = profile_data.get("goals", ["general fitness"])
            equipment = profile_data.get("equipment", [])

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
            response = await self.client.chat.completions.create(
                model=self.deployment,
                messages=[
                    {
                        "role": "system",
                        "content": "You are an expert fitness coach. Create safe, effective workout plans. Always prioritize proper form and safety. Return only valid JSON."
                    },
                    {"role": "user", "content": prompt}
                ],
                response_format={"type": "json_object"},
                max_tokens=2000,
                temperature=0.7
            )

            # Parse response
            content = response.choices[0].message.content
            if not content:
                raise ValueError("Empty response from OpenAI")
            workout_data = json.loads(content)

            # Add metadata
            workout_data["metadata"] = {
                "difficulty": difficulty,
                "estimatedDuration": duration,
                "equipmentNeeded": equipment if equipment else [],
                "aiProviderUsed": "azure-openai-gpt-4o-mini",
                "generationTime": time.time() - start_time,
                "tags": (focus_areas or []) + (goals if isinstance(goals, list) else [goals])
            }

            # Ensure required fields exist
            workout_data.setdefault("name", "Custom Workout")
            workout_data.setdefault("description", "AI-generated workout plan")
            workout_data.setdefault("exercises", [])
            workout_data.setdefault("durationMinutes", duration)
            workout_data.setdefault("difficulty", difficulty)
            workout_data.setdefault("equipment", equipment)
            workout_data.setdefault("aiGenerated", True)

            return workout_data

        except Exception as e:
            logger.error(f"Error generating workout: {type(e).__name__}: {str(e)}")
            raise

    def _build_workout_prompt(
        self,
        fitness_level: str,
        goals: List[str],
        equipment: List[str],
        duration: int,
        focus_areas: List[str],
        difficulty: str
    ) -> str:
        """Build the workout generation prompt"""
        goals_str = ', '.join(goals) if goals else 'general fitness'
        equipment_str = ', '.join(equipment) if equipment else 'bodyweight only'
        focus_str = ', '.join(focus_areas) if focus_areas else 'full body'

        return f"""Create a {duration}-minute workout plan for a {fitness_level} fitness level user.

Goals: {goals_str}
Available Equipment: {equipment_str}
Focus Areas: {focus_str}
Difficulty: {difficulty}

Return a JSON object with this exact structure:
{{
  "name": "Descriptive workout name",
  "description": "Brief description of the workout",
  "exercises": [
    {{
      "name": "Exercise name",
      "sets": 3,
      "reps": "12",
      "rest": "60s",
      "notes": "Form tips or modifications"
    }}
  ],
  "warmup": "5-minute warmup description",
  "cooldown": "5-minute cooldown description",
  "tips": ["Safety tip 1", "Performance tip 2"],
  "durationMinutes": {duration},
  "difficulty": "{difficulty}",
  "equipment": {json.dumps(equipment if equipment else [])}
}}

Requirements:
1. Exercises must be appropriate for {fitness_level} fitness level
2. Use only the available equipment listed
3. Include proper warmup and cooldown
4. Prioritize safety and proper form
5. Total workout should fit within {duration} minutes
6. Include 6-10 exercises for a complete workout"""

    async def coach_chat(
        self,
        message: str,
        history: List[Dict[str, Any]],
        user_context: Dict[str, Any]
    ) -> str:
        """Generate AI coach response"""
        try:
            if not self.client:
                raise ValueError("OpenAI client not initialized")

            profile_data = user_context.get("profile", {})

            system_prompt = f"""You are a friendly, knowledgeable AI fitness coach named Vigor Coach.

User Profile:
- Fitness Level: {profile_data.get('fitnessLevel', 'beginner')}
- Goals: {profile_data.get('goals', ['general fitness'])}
- Available Equipment: {profile_data.get('equipment', ['bodyweight'])}

Guidelines:
1. Be encouraging, supportive, and motivating
2. Provide actionable, specific advice
3. Prioritize safety - recommend consulting a doctor for medical concerns
4. Keep responses concise but helpful (2-4 paragraphs max)
5. Reference the user's profile when relevant
6. Use simple language, avoid jargon
7. If asked about nutrition, give general healthy eating advice but recommend consulting a nutritionist for specific plans"""

            messages = [{"role": "system", "content": system_prompt}]

            # Add conversation history (last 10 messages)
            for msg in history[-10:]:
                messages.append({
                    "role": msg.get("role", "user"),
                    "content": msg.get("content", "")
                })

            messages.append({"role": "user", "content": message})

            response = await self.client.chat.completions.create(
                model=self.deployment,
                messages=messages,  # type: ignore
                max_tokens=500,
                temperature=0.8
            )

            return response.choices[0].message.content or "I apologize, but I couldn't generate a response. Please try again."

        except Exception as e:
            logger.error(f"Error in coach chat: {type(e).__name__}: {str(e)}")
            raise

    async def analyze_workout(
        self,
        workout_data: Dict[str, Any],
        user_feedback: str
    ) -> Dict[str, Any]:
        """Analyze completed workout and provide feedback"""
        try:
            if not self.client:
                raise ValueError("OpenAI client not initialized")

            prompt = f"""Analyze this completed workout and provide constructive feedback.

Workout: {json.dumps(workout_data, indent=2)}

User Feedback: {user_feedback}

Provide a JSON response with:
{{
  "summary": "Brief workout summary",
  "positives": ["What went well"],
  "improvements": ["Areas to improve"],
  "recommendations": ["Specific recommendations for next time"],
  "motivationalMessage": "Encouraging closing message"
}}"""

            response = await self.client.chat.completions.create(
                model=self.deployment,
                messages=[
                    {
                        "role": "system",
                        "content": "You are an expert fitness coach providing workout analysis. Be encouraging but honest. Return only valid JSON."
                    },
                    {"role": "user", "content": prompt}
                ],
                response_format={"type": "json_object"},
                max_tokens=1000,
                temperature=0.7
            )

            content = response.choices[0].message.content
            if not content:
                raise ValueError("Empty response from OpenAI")
            return json.loads(content)

        except Exception as e:
            logger.error(f"Error analyzing workout: {type(e).__name__}: {str(e)}")
            raise

    def is_available(self) -> bool:
        """Check if the OpenAI client is properly configured"""
        return self.client is not None
