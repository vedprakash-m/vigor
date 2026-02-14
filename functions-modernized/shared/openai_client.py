"""
Azure OpenAI client for Vigor Functions
Single LLM provider using gpt-5-mini for workout generation and AI coaching
Deployed in vigor-rg alongside other Azure resources
Uses the v1 API pattern for Azure AI Foundry
"""

import json
import logging
import time
from typing import Any, Dict, List, Optional

from openai import AsyncOpenAI
from pydantic import BaseModel, Field, ValidationError

from .config import get_settings

logger = logging.getLogger(__name__)


# ── Response validation schemas ──────────────────────────────────────────────


class WorkoutExerciseSchema(BaseModel):
    """Schema for a single exercise in an AI-generated workout."""
    name: str
    sets: int = Field(ge=1, le=10, default=3)
    reps: Optional[str] = None
    rest: Optional[str] = None
    notes: Optional[str] = None


class WorkoutResponseSchema(BaseModel):
    """Schema for validating AI-generated workout JSON responses."""
    name: str = "Custom Workout"
    description: str = "AI-generated workout plan"
    exercises: List[WorkoutExerciseSchema] = Field(default_factory=list, max_length=20)
    warmup: Optional[str] = None
    cooldown: Optional[str] = None
    tips: List[str] = Field(default_factory=list)
    durationMinutes: int = Field(ge=5, le=120, default=45)
    difficulty: str = "moderate"
    equipment: List[str] = Field(default_factory=list)


class WorkoutAnalysisSchema(BaseModel):
    """Schema for validating AI workout analysis responses."""
    summary: str = ""
    positives: List[str] = Field(default_factory=list)
    improvements: List[str] = Field(default_factory=list)
    recommendations: List[str] = Field(default_factory=list)
    motivationalMessage: str = ""


class OpenAIClient:
    """Azure OpenAI gpt-5-mini client for AI operations"""

    def __init__(self):
        self.settings = get_settings()
        self.deployment = self.settings.AZURE_OPENAI_DEPLOYMENT or "gpt-5-mini"
        self.client: Optional[AsyncOpenAI] = None
        self._initialize_client()

    def _initialize_client(self):
        """Initialize Azure OpenAI client using v1 API pattern"""
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

            # Build base_url for v1 API (append /openai/v1 to the base endpoint)
            # Strip any trailing slashes and path segments first
            base_endpoint = endpoint.rstrip("/")
            # If endpoint contains /api/projects/, extract the base
            if "/api/projects/" in base_endpoint:
                # For Foundry endpoints like https://xxx.services.ai.azure.com/api/projects/xxx
                # We need: https://xxx.services.ai.azure.com/openai/v1
                base_endpoint = base_endpoint.split("/api/projects/")[0]
            base_url = f"{base_endpoint}/openai/v1"

            # Use OpenAI client with base_url (v1 API - no api_version needed)
            self.client = AsyncOpenAI(
                api_key=api_key,
                base_url=base_url,
            )
            logger.info(
                f"Azure OpenAI client initialized with deployment: {self.deployment}, base_url: {base_url}"
            )

        except Exception as e:
            logger.error(
                f"Failed to initialize Azure OpenAI client: {type(e).__name__}: {str(e)}"
            )
            self.client = None

    async def generate_workout(
        self, user_profile: Dict[str, Any], preferences: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Generate personalized workout using OpenAI gpt-5-mini"""
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
                difficulty=difficulty,
            )

            # Generate content
            response = await self.client.chat.completions.create(
                model=self.deployment,
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are an expert fitness coach. Create safe, "
                            "effective workout plans. Always prioritize proper "
                            "form and safety. You MUST respond with valid JSON only, no markdown."
                        ),
                    },
                    {"role": "user", "content": prompt},
                ],
                max_completion_tokens=2000,
            )

            # Parse and validate response through schema
            logger.info(f"OpenAI response: {response}")
            content = response.choices[0].message.content
            logger.info(f"Response content: {content}")
            if not content:
                raise ValueError("Empty response from OpenAI")

            # Strip markdown fences if LLM wraps JSON
            stripped = content.strip()
            if stripped.startswith("```"):
                stripped = stripped.split("\n", 1)[-1].rsplit("```", 1)[0].strip()

            raw_data = json.loads(stripped)

            # Validate through Pydantic schema
            try:
                validated = WorkoutResponseSchema(**raw_data)
                workout_data = validated.model_dump()
            except ValidationError as ve:
                logger.warning(f"Workout response failed schema validation: {ve}")
                # Fall back to raw data with safety defaults
                workout_data = raw_data
                workout_data.setdefault("name", "Custom Workout")
                workout_data.setdefault("description", "AI-generated workout plan")
                workout_data.setdefault("exercises", [])
                workout_data.setdefault("durationMinutes", duration)
                workout_data.setdefault("difficulty", difficulty)
                workout_data.setdefault("equipment", equipment)

            # Add metadata
            workout_data["metadata"] = {
                "difficulty": difficulty,
                "estimatedDuration": duration,
                "equipmentNeeded": equipment if equipment else [],
                "aiProviderUsed": "azure-openai-gpt-5-mini",
                "generationTime": time.time() - start_time,
                "tags": (focus_areas or [])
                + (goals if isinstance(goals, list) else [goals]),
            }

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
        difficulty: str,
    ) -> str:
        """Build the workout generation prompt"""
        goals_str = ", ".join(goals) if goals else "general fitness"
        equipment_str = ", ".join(equipment) if equipment else "bodyweight only"
        focus_str = ", ".join(focus_areas) if focus_areas else "full body"

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
        self, message: str, history: List[Dict[str, Any]], user_context: Dict[str, Any]
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
7. For nutrition, give general advice and recommend consulting a nutritionist"""

            messages = [{"role": "system", "content": system_prompt}]

            # Add conversation history (last 10 messages)
            for msg in history[-10:]:
                messages.append(
                    {"role": msg.get("role", "user"), "content": msg.get("content", "")}
                )

            messages.append({"role": "user", "content": message})

            response = await self.client.chat.completions.create(
                model=self.deployment,
                messages=messages,  # type: ignore
                max_completion_tokens=500,
            )

            logger.info(f"Coach chat response: {response}")
            message = response.choices[0].message
            logger.info(f"Message object: {message}")

            # Try content first, then check for reasoning_content (for reasoning models)
            content = message.content
            if not content and hasattr(message, 'reasoning_content'):
                content = getattr(message, 'reasoning_content', None)

            return (
                content
                or "I apologize, but I couldn't generate a response. Please try again."
            )

        except Exception as e:
            logger.error(f"Error in coach chat: {type(e).__name__}: {str(e)}")
            raise

    async def analyze_workout(
        self, workout_data: Dict[str, Any], user_feedback: str
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
                        "content": (
                            "You are an expert fitness coach providing workout "
                            "analysis. Be encouraging but honest. You MUST respond with valid JSON only, no markdown."
                        ),
                    },
                    {"role": "user", "content": prompt},
                ],
                max_completion_tokens=1000,
            )

            content = response.choices[0].message.content
            if not content:
                raise ValueError("Empty response from OpenAI")

            # Strip markdown fences if LLM wraps JSON
            stripped = content.strip()
            if stripped.startswith("```"):
                stripped = stripped.split("\n", 1)[-1].rsplit("```", 1)[0].strip()

            raw_data = json.loads(stripped)

            # Validate through Pydantic schema
            try:
                validated = WorkoutAnalysisSchema(**raw_data)
                return validated.model_dump()
            except ValidationError as ve:
                logger.warning(f"Workout analysis failed schema validation: {ve}")
                return raw_data

        except Exception as e:
            logger.error(f"Error analyzing workout: {type(e).__name__}: {str(e)}")
            raise

    def is_available(self) -> bool:
        """Check if the OpenAI client is properly configured"""
        return self.client is not None
