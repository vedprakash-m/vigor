import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from api.services.usage_tracking import UsageTrackingService
from core.ai import analyze_workout_log, generate_workout_plan, get_ai_coach_response
from core.config import get_settings
from database.models import AICoachMessage, UserProfile
from database.sql_models import AICoachMessageDB, WorkoutLogDB

settings = get_settings()


async def chat_with_ai_coach(
    db: Session,
    user: UserProfile,
    message: str,
    conversation_history: Optional[List[Dict[str, str]]] = None,
) -> str:
    """Chat with the AI coach with usage tracking."""

    # Note: Since this function now takes a regular Session instead of AsyncSession,
    # we'll need to adapt the async operations or use sync alternatives

    if not settings.OPENAI_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI service is not available",
        )

    # Get recent conversation history if not provided
    if conversation_history is None:
        recent_messages = (
            db.query(AICoachMessageDB)
            .filter(AICoachMessageDB.user_id == user.id)
            .order_by(AICoachMessageDB.created_at.desc())
            .limit(5)
            .all()
        )

        conversation_history = []
        for msg in reversed(recent_messages):  # Reverse to get chronological order
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

    # Get AI response
    ai_response = await get_ai_coach_response(user, message, conversation_history)

    # Save the conversation to database
    db_message = AICoachMessageDB(
        id=str(uuid.uuid4()),
        user_id=user.id,
        message=message,
        response=ai_response,
        context={"user_profile": user_profile},
    )

    db.add(db_message)
    db.commit()

    return ai_response


async def generate_ai_workout_plan(
    db: Session,
    user: UserProfile,
    goals: Optional[List[str]] = None,
    equipment: Optional[str] = None,
    duration_minutes: int = 45,
    focus_areas: Optional[List[str]] = None,
) -> Dict[str, Any]:
    """Generate a personalized workout plan using AI."""

    if not settings.OPENAI_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="AI service is not available",
        )

    # Use user's preferences if not provided
    goals = goals or ([g.value for g in user.goals] if user.goals else None)
    equipment = equipment or user.equipment

    try:
        workout_plan = await generate_workout_plan(
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

    # Get the workout log
    workout_log = (
        db.query(WorkoutLogDB)
        .filter(WorkoutLogDB.id == workout_log_id, WorkoutLogDB.user_id == user.id)
        .first()
    )

    if not workout_log:
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
    messages = (
        db.query(AICoachMessageDB)
        .filter(AICoachMessageDB.user_id == user_id)
        .order_by(AICoachMessageDB.created_at.desc())
        .limit(limit)
        .all()
    )

    return [AICoachMessage.model_validate(msg) for msg in messages]
