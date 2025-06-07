"""
AI module for fitness coaching and workout plan generation.
"""

import json
from typing import Any, Dict, List, Optional

from core.admin_llm_manager import AdminLLMManager
from core.config import get_settings
from database.connection import get_db
from database.models import UserProfile

settings = get_settings()


async def generate_workout_plan(
    user_profile: UserProfile,
    goals: Optional[List[str]] = None,
    equipment: Optional[str] = None,
    duration_minutes: int = 45,
    focus_areas: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Generate personalized workout plan using AI.
    """
    # Use user's goals if not provided
    goals = (
        goals or [g.value for g in user_profile.goals] if user_profile.goals else None
    )
    equipment = equipment or user_profile.equipment

    system_prompt = """You are an expert fitness coach. Create personalized workout plans in JSON format only.
    Always respond with valid JSON that matches the required structure."""

    user_message = f"""
Create a personalized workout plan for a user with the following profile:
- Fitness Level: {user_profile.fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}
- Available Equipment: {equipment}
- Workout Duration: {duration_minutes} minutes
- Focus Areas: {', '.join(focus_areas) if focus_areas else 'Full body'}

Provide the workout plan in this exact JSON structure:
{{
    "name": "Workout Plan Name",
    "description": "Brief description",
    "exercises": [
        {{
            "name": "Exercise Name",
            "sets": 3,
            "reps": "8-12",
            "rest_seconds": 60,
            "instructions": "How to perform the exercise",
            "modifications": "Easier/harder variations"
        }}
    ],
    "duration_minutes": {duration_minutes},
    "difficulty": "Beginner/Intermediate/Advanced",
    "equipment_needed": ["equipment1", "equipment2"],
    "notes": "Additional tips and notes"
}}
"""

    try:
        # Get database session and create admin manager
        db = next(get_db())
        admin_manager = AdminLLMManager(db)

        # Use AdminLLMManager to make the AI call with cost tracking
        response, cost, provider = await admin_manager.chat_completion(
            messages=[{"role": "user", "content": user_message}],
            system_prompt=system_prompt,
            user_id=user_profile.id,
            endpoint="workout_generation",
            json_response=True,
            max_tokens=1000,
        )

        # Parse JSON response
        workout_data = json.loads(response)
        return workout_data  # type: ignore[no-any-return]

    except json.JSONDecodeError:
        # If JSON parsing fails, return a basic workout plan
        return {
            "name": "Basic Workout Plan",
            "description": "A simple workout plan generated for your fitness level",
            "exercises": [
                {
                    "name": "Bodyweight Squats",
                    "sets": 3,
                    "reps": "10-15",
                    "rest_seconds": 60,
                    "instructions": "Stand with feet shoulder-width apart, lower your body as if sitting back into a chair",
                    "modifications": "Hold onto a chair for support if needed",
                }
            ],
            "duration_minutes": duration_minutes,
            "difficulty": user_profile.fitness_level,
            "equipment_needed": [equipment] if equipment else [],
            "notes": "Start slowly and focus on proper form",
        }

    except Exception as e:
        # Log the error but don't expose internal details
        print(f"Error generating workout plan: {e}")
        return {
            "error": "Sorry, I'm having trouble generating a workout plan right now. Please try again later.",
            "name": "Error",
            "description": "Unable to generate workout plan",
            "exercises": [],
            "duration_minutes": duration_minutes,
            "difficulty": "Unknown",
            "equipment_needed": [],
            "notes": "Please try again later",
        }


async def get_ai_coach_response(
    user_profile: UserProfile,
    message: str,
    conversation_history: List[Dict[Any, Any]] | None = None,
) -> str:
    """
    Get response from AI fitness coach.
    """
    conversation_history = conversation_history or []

    system_prompt = """You are an expert fitness coach. Provide helpful, encouraging, and safe fitness advice.
    Always prioritize user safety and recommend consulting healthcare providers for medical concerns."""

    # Build context from user profile
    goals_str = (
        ", ".join([g.value for g in user_profile.goals])
        if user_profile.goals
        else "General fitness"
    )

    user_context = f"""
User Profile:
- Fitness Level: {user_profile.fitness_level}
- Goals: {goals_str}
- Available Equipment: {user_profile.equipment}
- Injuries/Limitations: {', '.join(user_profile.injuries) if user_profile.injuries else 'None'}

User's message: {message}
"""

    try:
        # Get database session and create admin manager
        db = next(get_db())
        admin_manager = AdminLLMManager(db)

        # Use AdminLLMManager for cost tracking
        response, cost, provider = await admin_manager.chat_completion(
            messages=[{"role": "user", "content": user_context}],
            system_prompt=system_prompt,
            user_id=user_profile.id,
            endpoint="coaching_chat",
            max_tokens=500,
        )

        return response

    except Exception as e:
        print(f"Error in AI coach response: {e}")
        return (
            "I'm sorry, I'm having some technical difficulties right now. "
            "Please try asking your question again in a moment."
        )


async def analyze_workout_log(
    user_profile: UserProfile, workout_data: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Analyze a completed workout and provide feedback.
    """
    system_prompt = """You are a fitness coach analyzing workout logs. Provide constructive feedback in JSON format only."""

    user_message = f"""
Analyze this workout for a user:
- Fitness Level: {user_profile.fitness_level}
- Goals: {', '.join(user_profile.goals) if user_profile.goals else 'General fitness'}

Workout Data: {json.dumps(workout_data)}

Provide analysis in this exact JSON structure:
{{
    "overall_assessment": "Overall performance summary",
    "strengths": ["strength1", "strength2"],
    "areas_for_improvement": ["area1", "area2"],
    "recommendations": ["recommendation1", "recommendation2"],
    "next_steps": "What to focus on next"
}}
"""

    try:
        # Get database session and create admin manager
        db = next(get_db())
        admin_manager = AdminLLMManager(db)

        response, cost, provider = await admin_manager.chat_completion(
            messages=[{"role": "user", "content": user_message}],
            system_prompt=system_prompt,
            user_id=user_profile.id,
            endpoint="workout_analysis",
            json_response=True,
            max_tokens=500,
        )

        return json.loads(response)  # type: ignore[no-any-return]

    except json.JSONDecodeError:
        return {
            "overall_assessment": "Good workout! Keep up the consistency.",
            "strengths": ["Completed the workout", "Showed up and put in effort"],
            "areas_for_improvement": ["Consider tracking more details"],
            "recommendations": ["Focus on proper form", "Gradually increase intensity"],
            "next_steps": "Continue with regular workouts and track progress",
        }

    except Exception as e:
        print(f"Error analyzing workout: {e}")
        return {
            "overall_assessment": "Unable to analyze workout at this time",
            "strengths": [],
            "areas_for_improvement": [],
            "recommendations": ["Please try the analysis again later"],
            "next_steps": "Continue with your fitness routine",
        }
