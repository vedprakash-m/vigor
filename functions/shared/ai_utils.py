"""
AI utilities for Azure Functions
This module contains shared AI functionality used by all AI-related functions
"""
import json
import logging
from typing import Any, Dict, List, Optional, Tuple

from .llm_providers import get_llm_provider


async def generate_workout_plan(
    fitness_level: str,
    goals: List[str],
    equipment: Optional[str] = None,
    duration_minutes: int = 45,
    focus_areas: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """
    Generate personalized workout plan using AI.
    """
    system_prompt = """You are an expert fitness coach. Create personalized workout plans in JSON format only.
    Always respond with valid JSON that matches the required structure."""

    user_message = f"""
Create a personalized workout plan for a user with the following profile:
- Fitness Level: {fitness_level}
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
        # Get LLM provider and make the call
        provider = get_llm_provider()
        response = await provider.chat_completion(
            messages=[{"role": "user", "content": user_message}],
            system_prompt=system_prompt,
            max_tokens=1000,
            temperature=0.7,
            json_response=True,
        )

        # Parse JSON response
        workout_data = json.loads(response)
        return workout_data

    except json.JSONDecodeError as e:
        logging.error(f"JSON parse error: {str(e)}")
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
            "difficulty": fitness_level,
            "equipment_needed": [equipment] if equipment else [],
            "notes": "Sorry, we encountered an issue generating your detailed plan. Here's a basic plan to get you started.",
        }
    except Exception as e:
        logging.error(f"Error generating workout plan: {str(e)}")
        raise


async def analyze_workout_performance(
    workout_data: Dict[str, Any],
    user_fitness_level: str,
    previous_workouts: Optional[List[Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """
    Analyze a completed workout and provide feedback.
    """
    system_prompt = """You are an expert fitness coach providing analysis on workout performance.
    Respond with concise, actionable feedback in JSON format."""

    # Build the prompt with workout data
    workout_details = json.dumps(workout_data, indent=2)
    previous_context = ""

    if previous_workouts and len(previous_workouts) > 0:
        previous_context = f"\nUser's previous {len(previous_workouts)} workouts for context: {json.dumps(previous_workouts, indent=2)}"

    user_message = f"""
Analyze this completed workout for a {user_fitness_level} level user:
{workout_details}
{previous_context}

Provide detailed feedback and suggestions in this JSON format:
{{
    "overall_performance": "Brief overall assessment",
    "achievements": ["Achievement 1", "Achievement 2"],
    "areas_to_improve": ["Area 1", "Area 2"],
    "suggested_modifications": "Specific suggestions for next workout",
    "progress_indicators": {{
        "intensity_level": "Assessment of workout intensity (Low/Medium/High)",
        "technique_focus": "Specific exercise form to focus on next time",
        "recovery_recommendations": "Suggestion for recovery"
    }}
}}
"""

    try:
        # Get LLM provider and make the call
        provider = get_llm_provider()
        response = await provider.chat_completion(
            messages=[{"role": "user", "content": user_message}],
            system_prompt=system_prompt,
            max_tokens=1000,
            temperature=0.7,
            json_response=True,
        )

        # Parse JSON response
        analysis_data = json.loads(response)
        return analysis_data

    except Exception as e:
        logging.error(f"Error analyzing workout: {str(e)}")

        # Return basic analysis on error
        return {
            "overall_performance": "We couldn't analyze your workout fully, but keep up the good work!",
            "achievements": ["Completed workout"],
            "areas_to_improve": ["Try recording more details in your next workout"],
            "suggested_modifications": "Continue with your current plan and focus on form",
            "progress_indicators": {
                "intensity_level": "Medium",
                "technique_focus": "Overall proper form",
                "recovery_recommendations": "Ensure proper hydration and rest"
            }
        }


async def get_ai_coach_response(
    user_message: str,
    user_fitness_level: str,
    user_goals: List[str],
    conversation_history: Optional[List[Dict[str, str]]] = None,
) -> str:
    """
    Get a response from the AI coach based on user message and history.
    """

    system_prompt = f"""You are an encouraging AI fitness coach helping a {user_fitness_level} level user reach these goals: {', '.join(user_goals)}.
    Keep responses positive, supportive, and focused on fitness advice. Be concise but personal and motivating.
    Do not provide medical advice or make claims about weight loss results.
    Focus on proper form, consistency, and sustainable habit building."""

    # Prepare conversation history
    messages = []
    if conversation_history:
        messages.extend(conversation_history)

    # Add the current user message
    messages.append({"role": "user", "content": user_message})

    try:
        # Get LLM provider and make the call
        provider = get_llm_provider()
        response = await provider.chat_completion(
            messages=messages,
            system_prompt=system_prompt,
            max_tokens=500,
            temperature=0.8,
            json_response=False,
        )

        return response

    except Exception as e:
        logging.error(f"Error getting AI coach response: {str(e)}")
        return "I'm sorry, I'm having trouble responding right now. Please try again in a moment."
