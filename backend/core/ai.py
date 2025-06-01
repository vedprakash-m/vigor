"""
AI module for fitness coaching and workout plan generation.
"""

import json
from typing import Any, Dict, List, Optional

from sqlalchemy.orm import Session

from core.admin_llm_manager import AdminLLMManager
from core.config import get_settings
from database.connection import get_db
from database.models import UserProfile

from .admin_llm_manager import get_admin_llm_manager

settings = get_settings()

# Initialize AdminLLMManager for proper cost tracking and provider management
admin_manager = AdminLLMManager()


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
    goals = goals or user_profile.goals
    equipment = equipment or user_profile.equipment

    prompt = f"""
Create a personalized workout plan for a user with the following profile:
- Fitness Level: {user_profile.fitness_level}
- Goals: {', '.join(goals) if goals else 'General fitness'}
- Available Equipment: {equipment}
- Workout Duration: {duration_minutes} minutes
- Focus Areas: {', '.join(focus_areas) if focus_areas else 'Full body'}

Please provide a detailed workout plan in JSON format with the following structure:
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
        # Use AdminLLMManager to make the AI call with cost tracking
        response = await admin_manager.make_ai_call(
            prompt=prompt,
            user_id=user_profile.id,
            call_type="workout_generation",
            context={
                "fitness_level": user_profile.fitness_level,
                "goals": goals,
                "equipment": equipment,
                "duration_minutes": duration_minutes,
            },
        )

        # Parse JSON response
        workout_data = json.loads(response)
        return workout_data

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
                    "instructions": "Stand with feet shoulder-width apart, "
                    "lower your body as if sitting back into a chair",
                    "modifications": "Hold onto a chair for support if needed",
                }
            ],
            "duration_minutes": duration_minutes,
            "difficulty": user_profile.fitness_level,
            "equipment_needed": [equipment] if equipment else [],
            "notes": "Start slowly and focus on proper form",
        }

    except Exception:
        # Log the error but don't expose internal details
        return {
            "error": "Sorry, I'm having trouble generating a workout plan right now. "
            "Please try again later.",
            "name": "Error",
            "description": "Unable to generate workout plan",
            "exercises": [],
            "duration_minutes": duration_minutes,
            "difficulty": "Unknown",
            "equipment_needed": [],
            "notes": "Please try again later",
        }


async def get_ai_coach_response(
    user_profile: UserProfile, message: str, conversation_history: List[Dict] = None
) -> str:
    """
    Get response from AI fitness coach.
    """
    conversation_history = conversation_history or []

    # Build context from user profile
    context = f"""
You are an expert fitness coach. Here's information about the user you're helping:
- Fitness Level: {user_profile.fitness_level}
- Goals: {', '.join(user_profile.goals) if user_profile.goals else 'General fitness'}
- Available Equipment: {user_profile.equipment}
- Injuries/Limitations: {', '.join(user_profile.injuries) if user_profile.injuries else 'None'}

Previous conversation context:
{json.dumps(conversation_history[-5:]) if conversation_history else 'No previous conversation'}

User's current message: {message}

Please provide helpful, encouraging, and safe fitness advice. Always prioritize user safety
and recommend consulting healthcare providers for medical concerns.
"""

    try:
        # Use AdminLLMManager for cost tracking
        response = await admin_manager.make_ai_call(
            prompt=context,
            user_id=user_profile.id,
            call_type="coaching_chat",
            context={
                "message": message,
                "conversation_length": len(conversation_history),
            },
        )

        return response

    except Exception:
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
    prompt = f"""
Analyze this workout log for a user with the following profile:
- Fitness Level: {user_profile.fitness_level}
- Goals: {', '.join(user_profile.goals) if user_profile.goals else 'General fitness'}

Workout Data: {json.dumps(workout_data)}

Please provide analysis in JSON format:
{{
    "overall_assessment": "Overall performance summary",
    "strengths": ["strength1", "strength2"],
    "areas_for_improvement": ["area1", "area2"],
    "recommendations": ["recommendation1", "recommendation2"],
    "next_steps": "What to focus on next"
}}
"""

    try:
        response = await admin_manager.make_ai_call(
            prompt=prompt,
            user_id=user_profile.id,
            call_type="workout_analysis",
            context={"workout_data": workout_data},
        )

        return json.loads(response)

    except json.JSONDecodeError:
        return {
            "overall_assessment": "Good workout! Keep up the consistency.",
            "strengths": ["Completed the workout", "Showed up and put in effort"],
            "areas_for_improvement": ["Consider tracking more details"],
            "recommendations": ["Focus on proper form", "Gradually increase intensity"],
            "next_steps": "Continue with regular workouts and track progress",
        }

    except Exception:
        return {
            "overall_assessment": "Unable to analyze workout at this time",
            "strengths": [],
            "areas_for_improvement": [],
            "recommendations": ["Please try the analysis again later"],
            "next_steps": "Continue with your fitness routine",
        }
