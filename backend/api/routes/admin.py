import uuid
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import desc, func
from sqlalchemy.orm import Session

from api.schemas.admin import (
    AdminSettingsResponse,
    AdminSettingsUpdate,
    AIProviderPriorityCreate,
    AIProviderPriorityResponse,
    AIUsageLogResponse,
    BudgetSettingsResponse,
    BudgetSettingsUpdate,
)
from core.admin_llm_manager import (
    AdminLLMManager,
    BudgetExceededException,
    BudgetMonitor,
    CostCalculator,
)
from core.security import get_current_user
from database.connection import get_db
from database.models import AIProviderPriority, AIUsageLog, BudgetSettings, UserProfile
from database.sql_models import AIProviderPriorityDB, AIUsageLogDB, BudgetSettingsDB

router = APIRouter(prefix="/admin", tags=["admin"])


# Request/Response Models
class AIProviderPriorityRequest(BaseModel):
    provider_name: str
    model_name: str
    priority: int
    is_enabled: bool = True
    max_daily_cost: Optional[float] = None
    max_weekly_cost: Optional[float] = None
    max_monthly_cost: Optional[float] = None


class BudgetSettingsRequest(BaseModel):
    total_weekly_budget: float
    total_monthly_budget: float
    alert_threshold_percentage: float = 80.0
    auto_disable_on_budget_exceeded: bool = True


class UsageStatsResponse(BaseModel):
    weekly_spending: float
    monthly_spending: float
    daily_spending: float
    total_requests_today: int
    total_requests_week: int
    avg_cost_per_request: float
    top_providers: List[dict]
    recent_usage: List[dict]


# Admin Authentication Check
async def verify_admin_user(
    current_user: UserProfile = Depends(get_current_user),
) -> UserProfile:
    """Verify that the current user has admin privileges."""
    # For now, check if username contains 'admin' - in production, use proper role system
    if "admin" not in current_user.username.lower():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Admin privileges required"
        )
    return current_user


# Provider Priority Management
@router.get("/ai-providers", response_model=List[AIProviderPriority])
async def get_ai_provider_priorities(
    db: Session = Depends(get_db), admin_user: UserProfile = Depends(verify_admin_user)
):
    """Get all AI provider priority settings."""
    priorities = (
        db.query(AIProviderPriorityDB).order_by(AIProviderPriorityDB.priority).all()
    )
    return [
        AIProviderPriority(
            id=p.id,
            provider_name=p.provider_name,
            model_name=p.model_name,
            priority=p.priority,
            is_enabled=p.is_enabled,
            max_daily_cost=p.max_daily_cost,
            max_weekly_cost=p.max_weekly_cost,
            max_monthly_cost=p.max_monthly_cost,
            created_at=p.created_at,
            updated_at=p.updated_at,
        )
        for p in priorities
    ]


@router.post("/ai-providers", response_model=AIProviderPriority)
async def create_ai_provider_priority(
    priority_data: AIProviderPriorityRequest,
    db: Session = Depends(get_db),
    admin_user: UserProfile = Depends(verify_admin_user),
):
    """Create new AI provider priority setting."""

    # Check if priority number already exists
    existing = (
        db.query(AIProviderPriorityDB)
        .filter(AIProviderPriorityDB.priority == priority_data.priority)
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Priority {priority_data.priority} already exists",
        )

    db_priority = AIProviderPriorityDB(
        id=str(uuid.uuid4()),
        provider_name=priority_data.provider_name,
        model_name=priority_data.model_name,
        priority=priority_data.priority,
        is_enabled=priority_data.is_enabled,
        max_daily_cost=priority_data.max_daily_cost,
        max_weekly_cost=priority_data.max_weekly_cost,
        max_monthly_cost=priority_data.max_monthly_cost,
    )

    db.add(db_priority)
    db.commit()
    db.refresh(db_priority)

    return AIProviderPriority(
        id=db_priority.id,
        provider_name=db_priority.provider_name,
        model_name=db_priority.model_name,
        priority=db_priority.priority,
        is_enabled=db_priority.is_enabled,
        max_daily_cost=db_priority.max_daily_cost,
        max_weekly_cost=db_priority.max_weekly_cost,
        max_monthly_cost=db_priority.max_monthly_cost,
        created_at=db_priority.created_at,
        updated_at=db_priority.updated_at,
    )


@router.put("/ai-providers/{provider_id}", response_model=AIProviderPriority)
async def update_ai_provider_priority(
    provider_id: str,
    priority_data: AIProviderPriorityRequest,
    db: Session = Depends(get_db),
    admin_user: UserProfile = Depends(verify_admin_user),
):
    """Update AI provider priority setting."""
    db_priority = (
        db.query(AIProviderPriorityDB)
        .filter(AIProviderPriorityDB.id == provider_id)
        .first()
    )

    if not db_priority:
        raise HTTPException(status_code=404, detail="Provider priority not found")

    # Check if new priority conflicts with existing (excluding current record)
    if priority_data.priority != db_priority.priority:
        existing = (
            db.query(AIProviderPriorityDB)
            .filter(
                AIProviderPriorityDB.priority == priority_data.priority,
                AIProviderPriorityDB.id != provider_id,
            )
            .first()
        )

        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Priority {priority_data.priority} already exists",
            )

    # Update fields
    db_priority.provider_name = priority_data.provider_name
    db_priority.model_name = priority_data.model_name
    db_priority.priority = priority_data.priority
    db_priority.is_enabled = priority_data.is_enabled
    db_priority.max_daily_cost = priority_data.max_daily_cost
    db_priority.max_weekly_cost = priority_data.max_weekly_cost
    db_priority.max_monthly_cost = priority_data.max_monthly_cost
    db_priority.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(db_priority)

    return AIProviderPriority(
        id=db_priority.id,
        provider_name=db_priority.provider_name,
        model_name=db_priority.model_name,
        priority=db_priority.priority,
        is_enabled=db_priority.is_enabled,
        max_daily_cost=db_priority.max_daily_cost,
        max_weekly_cost=db_priority.max_weekly_cost,
        max_monthly_cost=db_priority.max_monthly_cost,
        created_at=db_priority.created_at,
        updated_at=db_priority.updated_at,
    )


@router.delete("/ai-providers/{provider_id}")
async def delete_ai_provider_priority(
    provider_id: str,
    db: Session = Depends(get_db),
    admin_user: UserProfile = Depends(verify_admin_user),
):
    """Delete AI provider priority setting."""
    db_priority = (
        db.query(AIProviderPriorityDB)
        .filter(AIProviderPriorityDB.id == provider_id)
        .first()
    )

    if not db_priority:
        raise HTTPException(status_code=404, detail="Provider priority not found")

    db.delete(db_priority)
    db.commit()

    return {"message": "Provider priority deleted successfully"}


# Budget Management
@router.get("/budget", response_model=Optional[BudgetSettings])
async def get_budget_settings(
    db: Session = Depends(get_db), admin_user: UserProfile = Depends(verify_admin_user)
):
    """Get current budget settings."""
    budget = db.query(BudgetSettingsDB).first()
    if not budget:
        return None

    return BudgetSettings(
        id=budget.id,
        total_weekly_budget=budget.total_weekly_budget,
        total_monthly_budget=budget.total_monthly_budget,
        alert_threshold_percentage=budget.alert_threshold_percentage,
        auto_disable_on_budget_exceeded=budget.auto_disable_on_budget_exceeded,
        created_at=budget.created_at,
        updated_at=budget.updated_at,
    )


@router.post("/budget", response_model=BudgetSettings)
async def create_or_update_budget_settings(
    budget_data: BudgetSettingsRequest,
    db: Session = Depends(get_db),
    admin_user: UserProfile = Depends(verify_admin_user),
):
    """Create or update budget settings."""
    existing_budget = db.query(BudgetSettingsDB).first()

    if existing_budget:
        # Update existing
        existing_budget.total_weekly_budget = budget_data.total_weekly_budget
        existing_budget.total_monthly_budget = budget_data.total_monthly_budget
        existing_budget.alert_threshold_percentage = (
            budget_data.alert_threshold_percentage
        )
        existing_budget.auto_disable_on_budget_exceeded = (
            budget_data.auto_disable_on_budget_exceeded
        )
        existing_budget.updated_at = datetime.utcnow()

        db.commit()
        db.refresh(existing_budget)
        budget = existing_budget
    else:
        # Create new
        budget = BudgetSettingsDB(
            id=str(uuid.uuid4()),
            total_weekly_budget=budget_data.total_weekly_budget,
            total_monthly_budget=budget_data.total_monthly_budget,
            alert_threshold_percentage=budget_data.alert_threshold_percentage,
            auto_disable_on_budget_exceeded=budget_data.auto_disable_on_budget_exceeded,
        )

        db.add(budget)
        db.commit()
        db.refresh(budget)

    return BudgetSettings(
        id=budget.id,
        total_weekly_budget=budget.total_weekly_budget,
        total_monthly_budget=budget.total_monthly_budget,
        alert_threshold_percentage=budget.alert_threshold_percentage,
        auto_disable_on_budget_exceeded=budget.auto_disable_on_budget_exceeded,
        created_at=budget.created_at,
        updated_at=budget.updated_at,
    )


# Usage Analytics
@router.get("/usage-stats", response_model=UsageStatsResponse)
async def get_usage_statistics(
    db: Session = Depends(get_db), admin_user: UserProfile = Depends(verify_admin_user)
):
    """Get comprehensive AI usage statistics."""
    budget_monitor = BudgetMonitor(db)

    # Basic spending stats
    weekly_spending = budget_monitor.get_weekly_spending()
    monthly_spending = budget_monitor.get_monthly_spending()

    # Daily stats
    day_start = datetime.now() - timedelta(days=1)
    daily_result = (
        db.query(
            func.sum(AIUsageLogDB.cost).label("total_cost"),
            func.count(AIUsageLogDB.id).label("total_requests"),
        )
        .filter(AIUsageLogDB.created_at >= day_start, AIUsageLogDB.success == True)
        .first()
    )

    daily_spending = daily_result.total_cost or 0.0
    daily_requests = daily_result.total_requests or 0

    # Weekly request count
    week_start = datetime.now() - timedelta(days=7)
    weekly_requests = (
        db.query(func.count(AIUsageLogDB.id))
        .filter(AIUsageLogDB.created_at >= week_start, AIUsageLogDB.success == True)
        .scalar()
        or 0
    )

    # Average cost per request
    avg_cost = (weekly_spending / weekly_requests) if weekly_requests > 0 else 0.0

    # Top providers by usage
    top_providers = (
        db.query(
            AIUsageLogDB.provider_name,
            func.count(AIUsageLogDB.id).label("request_count"),
            func.sum(AIUsageLogDB.cost).label("total_cost"),
        )
        .filter(AIUsageLogDB.created_at >= week_start, AIUsageLogDB.success == True)
        .group_by(AIUsageLogDB.provider_name)
        .order_by(desc(func.count(AIUsageLogDB.id)))
        .limit(5)
        .all()
    )

    # Recent usage logs
    recent_logs = (
        db.query(AIUsageLogDB).order_by(desc(AIUsageLogDB.created_at)).limit(10).all()
    )

    return UsageStatsResponse(
        weekly_spending=weekly_spending,
        monthly_spending=monthly_spending,
        daily_spending=daily_spending,
        total_requests_today=daily_requests,
        total_requests_week=weekly_requests,
        avg_cost_per_request=avg_cost,
        top_providers=[
            {
                "provider": provider.provider_name,
                "requests": provider.request_count,
                "cost": float(provider.total_cost),
            }
            for provider in top_providers
        ],
        recent_usage=[
            {
                "id": log.id,
                "provider": log.provider_name,
                "model": log.model_name,
                "endpoint": log.endpoint,
                "cost": float(log.cost),
                "success": log.success,
                "created_at": log.created_at.isoformat(),
            }
            for log in recent_logs
        ],
    )


@router.get("/cost-breakdown")
async def get_cost_breakdown(
    days: int = 7,
    db: Session = Depends(get_db),
    admin_user: UserProfile = Depends(verify_admin_user),
):
    """Get detailed cost breakdown by provider and model."""
    start_date = datetime.now() - timedelta(days=days)

    breakdown = (
        db.query(
            AIUsageLogDB.provider_name,
            AIUsageLogDB.model_name,
            func.count(AIUsageLogDB.id).label("request_count"),
            func.sum(AIUsageLogDB.cost).label("total_cost"),
            func.avg(AIUsageLogDB.response_time_ms).label("avg_response_time"),
            func.sum(AIUsageLogDB.input_tokens).label("total_input_tokens"),
            func.sum(AIUsageLogDB.output_tokens).label("total_output_tokens"),
        )
        .filter(AIUsageLogDB.created_at >= start_date, AIUsageLogDB.success == True)
        .group_by(AIUsageLogDB.provider_name, AIUsageLogDB.model_name)
        .order_by(desc(func.sum(AIUsageLogDB.cost)))
        .all()
    )

    return {
        "period_days": days,
        "breakdown": [
            {
                "provider": item.provider_name,
                "model": item.model_name,
                "requests": item.request_count,
                "total_cost": float(item.total_cost),
                "avg_cost_per_request": (
                    float(item.total_cost / item.request_count)
                    if item.request_count > 0
                    else 0
                ),
                "avg_response_time_ms": float(item.avg_response_time or 0),
                "total_input_tokens": item.total_input_tokens,
                "total_output_tokens": item.total_output_tokens,
            }
            for item in breakdown
        ],
    }
