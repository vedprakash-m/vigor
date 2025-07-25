"""
Gamification API endpoints for badges, streaks, and achievements.
Implements PRD gamification requirements including streak tracking, badge system, and progress analytics.
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy.ext.asyncio import AsyncSession

from api.dependencies import get_current_user
from api.schemas.user import UserResponse
from database.database import get_db_session
from database.repositories import user_repository, workout_repository

# Rate limiting
limiter = Limiter(key_func=get_remote_address)

router = APIRouter(prefix="/gamification", tags=["gamification"])


# Pydantic models for gamification
class StreakInfo(BaseModel):
    type: str = Field(..., description="Type of streak: daily, weekly, monthly")
    current: int = Field(..., description="Current streak count")
    best: int = Field(..., description="Best streak achieved")
    last_updated: datetime = Field(..., description="Last update timestamp")
    is_active: bool = Field(..., description="Whether streak is currently active")


class Badge(BaseModel):
    id: str
    name: str
    description: str
    icon: str
    category: str = Field(
        ..., description="Badge category: streak, achievement, milestone, exploration"
    )
    unlocked_at: Optional[datetime] = None
    progress: Optional[Dict[str, int]] = None


class GamificationStats(BaseModel):
    total_points: int
    level: int
    streaks: Dict[str, StreakInfo]
    badges: List[Badge]
    achievements: List[Badge]
    weekly_consistency: int
    ai_interactions: int
    workout_count: int
    equipment_types_used: List[str]


class WorkoutCompletionEvent(BaseModel):
    completed_at: datetime
    workout_type: Optional[str] = None
    equipment_used: Optional[List[str]] = None


# Badge definitions from PRD specifications
BADGE_DEFINITIONS = {
    "fitness_freshman": {
        "name": "Fitness Freshman",
        "description": "Complete your first workout",
        "icon": "🎓",
        "category": "milestone",
        "requirements": {"workout_count": 1},
    },
    "week_warrior": {
        "name": "Week Warrior",
        "description": "Complete 7 consecutive days of workouts",
        "icon": "⚔️",
        "category": "streak",
        "requirements": {"daily_streak": 7},
    },
    "form_master": {
        "name": "Form Master",
        "description": "Complete 50 workouts with AI form feedback",
        "icon": "🎯",
        "category": "achievement",
        "requirements": {"workout_count": 50},
    },
    "equipment_adapter": {
        "name": "Equipment Adapter",
        "description": "Use 5+ different equipment types",
        "icon": "🏋️",
        "category": "exploration",
        "requirements": {"equipment_types": 5},
    },
    "coach_conversationalist": {
        "name": "Coach Conversationalist",
        "description": "100+ meaningful AI coaching interactions",
        "icon": "💬",
        "category": "achievement",
        "requirements": {"ai_interactions": 100},
    },
    "plateau_buster": {
        "name": "Plateau Buster",
        "description": "Achieve 3+ personal records in a month",
        "icon": "📈",
        "category": "milestone",
        "requirements": {"monthly_prs": 3},
    },
    "early_bird": {
        "name": "Early Bird",
        "description": "Complete 20 morning workouts (before 9 AM)",
        "icon": "🌅",
        "category": "achievement",
        "requirements": {"morning_workouts": 20},
    },
    "consistency_king": {
        "name": "Consistency King",
        "description": "Maintain 30+ day streaks",
        "icon": "👑",
        "category": "streak",
        "requirements": {"daily_streak": 30},
    },
    "ai_explorer": {
        "name": "AI Explorer",
        "description": "Use all 3 AI providers (OpenAI, Gemini, Perplexity)",
        "icon": "🤖",
        "category": "exploration",
        "requirements": {"ai_providers": 3},
    },
    "month_champion": {
        "name": "Month Champion",
        "description": "Maintain weekly consistency for a full month",
        "icon": "🏆",
        "category": "streak",
        "requirements": {"weekly_consistency": 4},
    },
}


# In-memory storage for now (TODO: Add to database)
user_gamification_data: Dict[str, Dict] = {}


def calculate_daily_streak(workout_dates: List[datetime]) -> StreakInfo:
    """Calculate daily workout streak from workout dates."""
    if not workout_dates:
        return StreakInfo(
            type="daily",
            current=0,
            best=0,
            last_updated=datetime.utcnow(),
            is_active=False,
        )

    # Sort dates in descending order
    dates = sorted([d.date() for d in workout_dates], reverse=True)
    today = datetime.utcnow().date()

    # Calculate current streak
    current_streak = 0
    current_date = today

    for workout_date in dates:
        date_diff = (current_date - workout_date).days

        if date_diff == 0 or date_diff == 1:
            current_streak += 1
            current_date = workout_date
        else:
            break

    # Calculate best streak
    best_streak = 0
    temp_streak = 1

    for i in range(1, len(dates)):
        date_diff = (dates[i - 1] - dates[i]).days
        if date_diff == 1:
            temp_streak += 1
        else:
            best_streak = max(best_streak, temp_streak)
            temp_streak = 1

    best_streak = max(best_streak, temp_streak, current_streak)

    return StreakInfo(
        type="daily",
        current=current_streak,
        best=best_streak,
        last_updated=datetime.utcnow(),
        is_active=current_streak > 0,
    )


def calculate_level(total_points: int) -> int:
    """Calculate user level based on total points."""
    if total_points < 100:
        return 1
    return int((total_points / 100) ** 0.5) + 1


def check_badge_unlocks(user_data: Dict) -> List[Badge]:
    """Check which badges should be unlocked based on user activity."""
    unlocked_badges = []
    existing_badges = {badge["id"] for badge in user_data.get("badges", [])}

    for badge_id, badge_def in BADGE_DEFINITIONS.items():
        if badge_id in existing_badges:
            continue

        requirements = badge_def["requirements"]
        should_unlock = False

        # Check requirements
        if "workout_count" in requirements:
            should_unlock = (
                user_data.get("workout_count", 0) >= requirements["workout_count"]
            )
        elif "daily_streak" in requirements:
            should_unlock = (
                user_data.get("daily_streak", {}).get("best", 0)
                >= requirements["daily_streak"]
            )
        elif "ai_interactions" in requirements:
            should_unlock = (
                user_data.get("ai_interactions", 0) >= requirements["ai_interactions"]
            )
        elif "equipment_types" in requirements:
            should_unlock = (
                len(user_data.get("equipment_types_used", []))
                >= requirements["equipment_types"]
            )
        elif "weekly_consistency" in requirements:
            should_unlock = (
                user_data.get("weekly_consistency", 0)
                >= requirements["weekly_consistency"]
            )

        if should_unlock:
            badge = Badge(
                id=badge_id,
                name=badge_def["name"],
                description=badge_def["description"],
                icon=badge_def["icon"],
                category=badge_def["category"],
                unlocked_at=datetime.utcnow(),
            )
            unlocked_badges.append(badge)

    return unlocked_badges


@router.get("/stats")
@limiter.limit("30/minute")
async def get_gamification_stats(
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> GamificationStats:
    """
    Get comprehensive gamification stats for the current user.
    """
    try:
        user_id = current_user.id

        # Get workout history for streak calculation
        workout_logs = await workout_repository.get_user_workout_logs(db, user_id)
        workout_dates = [log.completed_at for log in workout_logs if log.completed_at]

        # Calculate streaks
        daily_streak = calculate_daily_streak(workout_dates)

        # Weekly streak calculation (simplified)
        weekly_streak = StreakInfo(
            type="weekly",
            current=min(daily_streak.current // 3, 4),  # Rough weekly consistency
            best=min(daily_streak.best // 3, 8),
            last_updated=datetime.utcnow(),
            is_active=daily_streak.current >= 3,
        )

        # Monthly streak calculation (simplified)
        monthly_streak = StreakInfo(
            type="monthly",
            current=min(daily_streak.current // 14, 2),
            best=min(daily_streak.best // 14, 6),
            last_updated=datetime.utcnow(),
            is_active=daily_streak.current >= 14,
        )

        # Get or initialize user gamification data
        if user_id not in user_gamification_data:
            user_gamification_data[user_id] = {
                "total_points": len(workout_dates) * 10,  # 10 points per workout
                "badges": [],
                "ai_interactions": 0,
                "equipment_types_used": [],
                "weekly_consistency": min(daily_streak.current // 7, 4),
                "workout_count": len(workout_dates),
                "daily_streak": daily_streak.dict(),
            }

        user_data = user_gamification_data[user_id]
        user_data["workout_count"] = len(workout_dates)
        user_data["daily_streak"] = daily_streak.dict()
        user_data["total_points"] = len(workout_dates) * 10

        # Check for new badge unlocks
        new_badges = check_badge_unlocks(user_data)
        user_data["badges"].extend([badge.dict() for badge in new_badges])

        # Calculate level
        level = calculate_level(user_data["total_points"])

        return GamificationStats(
            total_points=user_data["total_points"],
            level=level,
            streaks={
                "daily": daily_streak,
                "weekly": weekly_streak,
                "monthly": monthly_streak,
            },
            badges=[Badge(**badge) for badge in user_data["badges"]],
            achievements=[
                Badge(**badge)
                for badge in user_data["badges"]
                if badge["category"] == "achievement"
            ],
            weekly_consistency=user_data.get("weekly_consistency", 0),
            ai_interactions=user_data.get("ai_interactions", 0),
            workout_count=user_data["workout_count"],
            equipment_types_used=user_data.get("equipment_types_used", []),
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch gamification stats: {str(e)}",
        )


@router.post("/workout-completed")
@limiter.limit("60/minute")
async def record_workout_completion(
    event: WorkoutCompletionEvent,
    current_user: UserResponse = Depends(get_current_user),
) -> Dict[str, str]:
    """
    Record workout completion and update gamification stats.
    """
    try:
        user_id = current_user.id

        # Initialize user data if needed
        if user_id not in user_gamification_data:
            user_gamification_data[user_id] = {
                "total_points": 0,
                "badges": [],
                "ai_interactions": 0,
                "equipment_types_used": [],
                "weekly_consistency": 0,
                "workout_count": 0,
            }

        user_data = user_gamification_data[user_id]

        # Award points for workout completion
        points_earned = 10
        user_data["total_points"] += points_earned
        user_data["workout_count"] = user_data.get("workout_count", 0) + 1

        # Track equipment usage
        if event.equipment_used:
            equipment_set = set(user_data.get("equipment_types_used", []))
            equipment_set.update(event.equipment_used)
            user_data["equipment_types_used"] = list(equipment_set)

        # Check for badge unlocks
        new_badges = check_badge_unlocks(user_data)
        if new_badges:
            user_data["badges"].extend([badge.dict() for badge in new_badges])

        return {
            "status": "success",
            "points_earned": str(points_earned),
            "new_badges": str(len(new_badges)),
            "total_points": str(user_data["total_points"]),
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to record workout completion: {str(e)}",
        )


@router.post("/ai-interaction")
@limiter.limit("100/minute")
async def record_ai_interaction(
    current_user: UserResponse = Depends(get_current_user),
) -> Dict[str, str]:
    """
    Record AI interaction for gamification tracking.
    """
    try:
        user_id = current_user.id

        if user_id not in user_gamification_data:
            user_gamification_data[user_id] = {
                "total_points": 0,
                "badges": [],
                "ai_interactions": 0,
                "equipment_types_used": [],
                "weekly_consistency": 0,
                "workout_count": 0,
            }

        user_data = user_gamification_data[user_id]
        user_data["ai_interactions"] = user_data.get("ai_interactions", 0) + 1

        # Award small points for AI interactions
        points_earned = 1
        user_data["total_points"] += points_earned

        # Check for badge unlocks
        new_badges = check_badge_unlocks(user_data)
        if new_badges:
            user_data["badges"].extend([badge.dict() for badge in new_badges])

        return {
            "status": "success",
            "ai_interactions": str(user_data["ai_interactions"]),
            "points_earned": str(points_earned),
            "new_badges": str(len(new_badges)),
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to record AI interaction: {str(e)}",
        )


@router.get("/badges")
async def get_available_badges(
    current_user: UserResponse = Depends(get_current_user),
) -> List[Badge]:
    """
    Get all available badges with progress information.
    """
    user_id = current_user.id
    user_data = user_gamification_data.get(user_id, {})
    unlocked_badges = {badge["id"] for badge in user_data.get("badges", [])}

    badges = []
    for badge_id, badge_def in BADGE_DEFINITIONS.items():
        # Calculate progress
        requirements = badge_def["requirements"]
        progress = None

        if "workout_count" in requirements:
            progress = {
                "current": user_data.get("workout_count", 0),
                "target": requirements["workout_count"],
            }
        elif "ai_interactions" in requirements:
            progress = {
                "current": user_data.get("ai_interactions", 0),
                "target": requirements["ai_interactions"],
            }
        elif "equipment_types" in requirements:
            progress = {
                "current": len(user_data.get("equipment_types_used", [])),
                "target": requirements["equipment_types"],
            }

        badge = Badge(
            id=badge_id,
            name=badge_def["name"],
            description=badge_def["description"],
            icon=badge_def["icon"],
            category=badge_def["category"],
            unlocked_at=datetime.utcnow() if badge_id in unlocked_badges else None,
            progress=progress,
        )
        badges.append(badge)

    return badges


@router.get("/leaderboard")
@limiter.limit("10/minute")
async def get_leaderboard(
    current_user: UserResponse = Depends(get_current_user),
) -> Dict[str, List[Dict]]:
    """
    Get anonymous leaderboard data for motivation.
    """
    # Create anonymous leaderboard from user data
    leaderboard_data = []

    for user_id, data in user_gamification_data.items():
        leaderboard_data.append(
            {
                "rank": 0,  # Will be calculated
                "username": f"User{hash(user_id) % 10000}",  # Anonymous
                "level": calculate_level(data.get("total_points", 0)),
                "total_points": data.get("total_points", 0),
                "daily_streak": data.get("daily_streak", {}).get("current", 0),
                "badges_count": len(data.get("badges", [])),
            }
        )

    # Sort by total points and assign ranks
    leaderboard_data.sort(key=lambda x: x["total_points"], reverse=True)
    for i, entry in enumerate(leaderboard_data):
        entry["rank"] = i + 1

    return {
        "top_points": leaderboard_data[:10],
        "top_streaks": sorted(
            leaderboard_data, key=lambda x: x["daily_streak"], reverse=True
        )[:10],
        "top_badges": sorted(
            leaderboard_data, key=lambda x: x["badges_count"], reverse=True
        )[:10],
    }
