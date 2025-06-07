from datetime import datetime
from typing import List, Optional

from api.schemas.ai import (ChatMessage, ChatResponse, GeneratedWorkoutPlan,
                            WorkoutAnalysis, WorkoutRecommendationRequest)
from api.services.ai import (analyze_user_workout, chat_with_ai_coach,
                             generate_ai_workout_plan,
                             get_conversation_history)
from core.config import get_settings
from core.llm_providers import get_llm_provider
from core.security import get_current_user
from database.connection import get_db
from database.models import UserProfile
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

router = APIRouter(prefix="/ai", tags=["ai"])


@router.get("/provider-status")
async def get_provider_status():
    """Get information about the current LLM provider."""
    settings = get_settings()
    provider = get_llm_provider()

    return {
        "configured_provider": settings.LLM_PROVIDER,
        "active_provider": provider.__class__.__name__,
        "is_available": provider.is_available(),
        "provider_info": {
            "openai": {
                "configured": bool(
                    settings.OPENAI_API_KEY
                    and settings.OPENAI_API_KEY
                    not in ["your-openai-api-key-here", "sk-placeholder"]
                ),
                "model": settings.OPENAI_MODEL,
            },
            "gemini": {
                "configured": bool(
                    settings.GEMINI_API_KEY
                    and settings.GEMINI_API_KEY != "your-gemini-api-key-here"
                ),
                "model": settings.GEMINI_MODEL,
            },
            "perplexity": {
                "configured": bool(
                    settings.PERPLEXITY_API_KEY
                    and settings.PERPLEXITY_API_KEY != "your-perplexity-api-key-here"
                ),
                "model": settings.PERPLEXITY_MODEL,
            },
        },
    }


@router.post("/chat", response_model=ChatResponse)
async def chat_with_coach(
    chat_message: ChatMessage,
    db: Session = Depends(get_db),
    current_user: UserProfile = Depends(get_current_user),
):
    """Chat with AI fitness coach."""
    try:
        response = await chat_with_ai_coach(
            db=db, user=current_user, message=chat_message.message
        )

        return ChatResponse(response=response, created_at=datetime.utcnow())
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get AI response: {str(e)}",
        )


@router.post("/workout-plan", response_model=GeneratedWorkoutPlan)
async def generate_workout_plan(
    request: WorkoutRecommendationRequest,
    db: Session = Depends(get_db),
    current_user: UserProfile = Depends(get_current_user),
):
    """Generate a personalized workout plan using AI."""
    try:
        workout_plan = await generate_ai_workout_plan(
            db=db,
            user=current_user,
            goals=request.goals,
            equipment=request.equipment,
            duration_minutes=request.duration_minutes,
            focus_areas=request.focus_areas,
        )

        return GeneratedWorkoutPlan(**workout_plan)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate workout plan: {str(e)}",
        )


@router.post("/analyze-workout/{workout_log_id}", response_model=WorkoutAnalysis)
async def analyze_workout(
    workout_log_id: str,
    db: Session = Depends(get_db),
    current_user: UserProfile = Depends(get_current_user),
):
    """Analyze a workout log and provide AI feedback."""
    try:
        analysis = await analyze_user_workout(
            db=db, user=current_user, workout_log_id=workout_log_id
        )

        return WorkoutAnalysis(**analysis)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to analyze workout: {str(e)}",
        )


@router.get("/conversation-history")
async def get_chat_history(
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: UserProfile = Depends(get_current_user),
):
    """Get conversation history with AI coach."""
    try:
        history = await get_conversation_history(
            db=db, user_id=current_user.id, limit=limit
        )

        return {"conversations": history}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get conversation history: {str(e)}",
        )
