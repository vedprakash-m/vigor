import os
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session


# Use direct AI functionality if function client isn't available
from core.ai import (
    analyze_workout_log,
)
from core.ai import generate_workout_plan as direct_generate_workout_plan
from core.ai import get_ai_coach_response as direct_get_ai_coach_response
from core.config import get_settings

# Import the new Functions client
from core.function_client import FunctionsClient
from database.models import AICoachMessage, UserProfile
from infrastructure.repositories.sqlalchemy_aicoach_repository import (
    SQLAlchemyAICoachMessageRepository,
)
from infrastructure.repositories.sqlalchemy_workoutlog_repository import (
    SQLAlchemyWorkoutLogRepository,
)

settings = get_settings()

# Check if we should use Azure Functions
USE_FUNCTIONS = os.environ.get("USE_FUNCTIONS", "true").lower() == "true"
functions_client = FunctionsClient() if USE_FUNCTIONS else None


async def chat_with_ai_coach(
    db: Session,
    user: UserProfile,
    message: str,
    conversation_history: Optional[List[Dict[str, str]]] = None,
) -> str:
    """Chat with the AI coach with usage tracking."""

    # Check if AI service is available
    if not USE_FUNCTIONS and not settings.OPENAI_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI service is not available",
        )

    # Get recent conversation history if not provided
    if conversation_history is None:
        repo = SQLAlchemyAICoachMessageRepository(db)
        recent_messages = await repo.list(user_id=user.id, limit=5)

        conversation_history = []
        for msg in reversed(recent_messages):
            conversation_history.extend(
                [
                    {"role": "user", "content": str(msg.message)},
                    {"role": "assistant", "content": str(msg.response)},
                ]
            )

    # Prepare user profile for AI context
    user_profile = {
        "fitness_level": str(user.fitness_level) if user.fitness_level else "",
        "goals": str(user.goals) if user.goals else "",
        "equipment": str(user.equipment) if user.equipment else "",
        "injuries": str(user.injuries) if user.injuries else "",
    }

    # Extract goals for function call
    goals = [g.value for g in user.goals] if user.goals else ["General fitness"]

    try:
        # Get AI response using either Function or direct approach
        if USE_FUNCTIONS and functions_client:
            # Use the Azure Function
            ai_response = await functions_client.coach_chat(
                message=message,
                fitness_level=user.fitness_level,
                goals=goals,
                conversation_history=conversation_history,
            )
        else:
            # Use direct approach as fallback
            ai_response = await direct_get_ai_coach_response(
                user, message, conversation_history
            )

        # Save the conversation to database
        repo = SQLAlchemyAICoachMessageRepository(db)
        await repo.add(
            AICoachMessage(
                id=str(uuid.uuid4()),
                user_id=user.id,
                message=message,
                response=ai_response,
                context={"user_profile": user_profile},
                created_at=datetime.utcnow(),
            )
        )

        return ai_response
    except Exception as e:
        # Log the error but return a friendly message
        import logging

        logging.error(f"Error in chat_with_ai_coach: {str(e)}")
        return "I'm having trouble connecting right now. Please try again in a moment."


async def generate_ai_workout_plan(
    db: Session,
    user: UserProfile,
    goals: Optional[List[str]] = None,
    equipment: Optional[str] = None,
    duration_minutes: int = 45,
    focus_areas: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """Generate a personalized workout plan using AI."""

    # Check if AI service is available
    if not USE_FUNCTIONS and not settings.OPENAI_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI service is not available",
        )

    # Use user's preferences if not provided
    goals = goals or ([g.value for g in user.goals] if user.goals else None)
    equipment = equipment or user.equipment

    try:
        if USE_FUNCTIONS and functions_client:
            # Use the Azure Function
            workout_plan = await functions_client.generate_workout_plan(
                fitness_level=user.fitness_level,
                goals=goals or ["General fitness"],
                equipment=equipment,
                duration_minutes=duration_minutes,
                focus_areas=focus_areas,
            )
        else:
            # Use direct approach as fallback
            workout_plan = await direct_generate_workout_plan(
                user_profile=user,
                goals=goals,
                equipment=equipment,
                duration_minutes=duration_minutes,
            )

        # Add any focus areas to the context
        if focus_areas:
            workout_plan["focus_areas"] = focus_areas

        return workout_plan

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate workout plan: {str(e)}",
        )


async def analyze_user_workout(
    db: Session, user: UserProfile, workout_log_id: str
) -> Dict[str, Any]:
    """Analyze a user's workout and provide feedback."""

    if not settings.OPENAI_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI service is not available",
        )

    log_repo = SQLAlchemyWorkoutLogRepository(db)
    workout_log = await log_repo.get(workout_log_id)
    if workout_log is None or workout_log.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Workout log not found"
        )

    # Prepare data for analysis
    workout_data = {
        "duration_minutes": workout_log.duration_minutes,
        "exercises": workout_log.exercises,
        "notes": workout_log.notes,
        "rating": workout_log.rating,
        "completed_at": workout_log.completed_at.isoformat(),
    }

    try:
        analysis = await analyze_workout_log(user, workout_data)
        return analysis

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze workout: {str(e)}",
        )


async def get_conversation_history(
    db: Session, user_id: str, limit: int = 20
) -> List[AICoachMessage]:
    """Get user's conversation history with AI coach."""
    repo = SQLAlchemyAICoachMessageRepository(db)
    return await repo.list(user_id=user_id, limit=limit)
