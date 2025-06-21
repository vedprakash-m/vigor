"""
Enterprise LLM Orchestration API Routes
Provides admin and user-facing endpoints for the LLM orchestration layer
"""

from datetime import datetime
from typing import Any, Optional, Union

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from core.llm_orchestration.config_manager import (
    ABTestConfiguration,
    BudgetConfiguration,
    BudgetResetPeriod,
    ModelPriority,
    RoutingRule,
)
from core.llm_orchestration.gateway import GatewayRequest
from core.llm_orchestration.key_vault import KeyVaultProvider, SecretReference
from core.llm_orchestration_init import get_llm_gateway
from core.security import get_current_admin_user, get_current_user
from database.connection import get_db
from database.models import UserProfile

router = APIRouter(prefix="/llm", tags=["LLM Orchestration"])


# Request/Response Models
class LLMRequest(BaseModel):
    prompt: str = Field(
        ..., min_length=1, max_length=50000, description="The prompt to send to the LLM"
    )
    task_type: Optional[str] = Field(
        None, description="Type of task (chat, coding, analysis, etc.)"
    )
    max_tokens: Optional[int] = Field(
        None, ge=1, le=32000, description="Maximum tokens to generate"
    )
    temperature: Optional[float] = Field(
        None, ge=0.0, le=2.0, description="Temperature for response generation"
    )
    stream: bool = Field(False, description="Whether to stream the response")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata")


class LLMResponse(BaseModel):
    content: str
    model_used: str
    provider: str
    request_id: str
    tokens_used: int
    cost_estimate: float
    latency_ms: int
    cached: bool
    user_id: str
    metadata: Optional[Dict[str, Any]] = None


class SystemStatusResponse(BaseModel):
    active_models: int
    total_models: int
    circuit_breakers: Dict[str, Any]
    cache_stats: Dict[str, Any]
    budget_status: Dict[str, Any]
    providers: Dict[str, Any]


class ModelConfigRequest(BaseModel):
    model_id: str = Field(..., description="Unique identifier for the model")
    provider: str = Field(..., description="LLM provider (openai, gemini, etc.)")
    model_name: str = Field(..., description="Provider-specific model name")
    api_key_secret_identifier: str = Field(
        ..., description="Key Vault secret identifier"
    )
    key_vault_provider: str = Field(
        ..., description="Key Vault provider (azure, aws, etc.)"
    )
    priority: int = Field(
        3, ge=1, le=5, description="Model priority (1=highest, 5=lowest)"
    )
    cost_per_token: float = Field(0.0001, ge=0, description="Cost per token")
    max_tokens: int = Field(4096, ge=1, description="Maximum tokens for this model")
    temperature: float = Field(0.7, ge=0, le=2, description="Default temperature")
    is_active: bool = Field(True, description="Whether the model is active")


class RoutingRuleRequest(BaseModel):
    rule_id: str = Field(..., description="Unique identifier for the rule")
    name: str = Field(..., description="Human-readable name")
    conditions: Dict[str, Any] = Field(..., description="Conditions for rule matching")
    target_models: List[str] = Field(
        ..., description="Target model IDs in priority order"
    )
    weight: float = Field(1.0, ge=0, description="Rule weight for prioritization")
    is_active: bool = Field(True, description="Whether the rule is active")


class ABTestRequest(BaseModel):
    test_id: str = Field(..., description="Unique identifier for the A/B test")
    name: str = Field(..., description="Human-readable name")
    description: str = Field(..., description="Test description")
    start_date: datetime = Field(..., description="Test start date")
    end_date: datetime = Field(..., description="Test end date")
    traffic_split: Dict[str, float] = Field(
        ..., description="Traffic split between variants"
    )
    model_variants: Dict[str, List[str]] = Field(
        ..., description="Model variants for each test group"
    )
    success_metrics: List[str] = Field(
        default_factory=list, description="Metrics to track"
    )


class BudgetConfigRequest(BaseModel):
    budget_id: str = Field(..., description="Unique identifier for the budget")
    name: str = Field(..., description="Human-readable name")
    total_budget: float = Field(..., gt=0, description="Total budget amount")
    reset_period: str = Field(
        ..., description="Budget reset period (daily, weekly, monthly, quarterly)"
    )
    alert_thresholds: List[float] = Field(
        default_factory=lambda: [0.5, 0.8, 0.95], description="Alert thresholds"
    )
    auto_disable_at_limit: bool = Field(
        True, description="Auto-disable when limit reached"
    )
    user_groups: List[str] = Field(
        default_factory=list, description="User groups (empty = global)"
    )


class UsageReportRequest(BaseModel):
    start_date: datetime
    end_date: datetime
    user_id: Optional[str] = None
    group_by: Optional[str] = Field(
        None, description="Group by: user, model, provider, day"
    )


# User-facing endpoints
@router.post("/chat", response_model=LLMResponse)
async def process_llm_request(
    request: LLMRequest,
    current_user: UserProfile = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Process an LLM request through the orchestration layer.
    Includes intelligent routing, caching, budget enforcement, and analytics.
    """
    try:
        gateway = get_llm_gateway()

        # Create gateway request
        gateway_request = GatewayRequest(
            prompt=request.prompt,
            user_id=str(current_user.id),
            task_type=request.task_type,
            user_tier=getattr(current_user, "tier", "standard"),
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            stream=request.stream,
            metadata=request.metadata,
        )

        # Process through gateway
        response = await gateway.process_request(gateway_request)

        return LLMResponse(
            content=response.content,
            model_used=response.model_used,
            provider=response.provider,
            request_id=response.request_id,
            tokens_used=response.tokens_used,
            cost_estimate=response.cost_estimate,
            latency_ms=response.latency_ms,
            cached=response.cached,
            user_id=response.user_id or str(current_user.id),
            metadata=response.metadata,
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"LLM request failed: {str(e)}",
        )


@router.post("/chat/stream")
async def process_llm_request_stream(
    request: LLMRequest,
    current_user: UserProfile = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Process a streaming LLM request through the orchestration layer.
    Returns real-time streaming response.
    """
    try:
        gateway = get_llm_gateway()

        # Create gateway request
        gateway_request = GatewayRequest(
            prompt=request.prompt,
            user_id=str(current_user.id),
            task_type=request.task_type,
            user_tier=getattr(current_user, "tier", "standard"),
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            stream=True,
            metadata=request.metadata,
        )

        async def stream_generator():
            async for chunk in gateway.process_stream(gateway_request):
                yield f"data: {chunk}\n\n"
            yield "data: [DONE]\n\n"

        return StreamingResponse(
            stream_generator(),
            media_type="text/plain",
            headers={"Cache-Control": "no-cache", "Connection": "keep-alive"},
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Streaming request failed: {str(e)}",
        )


@router.get("/status", response_model=SystemStatusResponse)
async def get_system_status(current_user: UserProfile = Depends(get_current_user)):
    """
    Get current status of the LLM orchestration system.
    Shows provider health, cache stats, and budget status.
    """
    try:
        gateway = get_llm_gateway()
        provider_status = await gateway.get_provider_status()

        return SystemStatusResponse(**provider_status)

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get system status: {str(e)}",
        )


@router.get("/usage-summary")
async def get_user_usage_summary(
    current_user: UserProfile = Depends(get_current_user), db: Session = Depends(get_db)
):
    """
    Get usage summary for the current user.
    Includes budget consumption, request counts, and cost breakdown.
    """
    try:
        gateway = get_llm_gateway()
        user_tier = getattr(current_user, "tier", "standard")

        usage_summary = await gateway.budget_manager.get_usage_summary(
            user_id=str(current_user.id), user_groups=[user_tier]
        )

        return usage_summary

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get usage summary: {str(e)}",
        )


# Admin endpoints
@router.post("/admin/models", dependencies=[Depends(get_current_admin_user)])
async def add_model_configuration(
    request: ModelConfigRequest, db: Session = Depends(get_db)
):
    """
    Admin endpoint to add a new LLM model configuration.
    Includes secure Key Vault integration.
    """
    try:
        gateway = get_llm_gateway()

        # Create secret reference
        secret_ref = SecretReference(
            provider=KeyVaultProvider(request.key_vault_provider),
            secret_identifier=request.api_key_secret_identifier,
        )

        # Add model configuration
        success = await gateway.admin_add_model(
            model_id=request.model_id,
            provider=request.provider,
            model_name=request.model_name,
            api_key_secret_ref=secret_ref,
            priority=ModelPriority(request.priority),
            cost_per_token=request.cost_per_token,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            is_active=request.is_active,
        )

        if success:
            return {"message": f"Model {request.model_id} added successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to add model configuration",
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add model: {str(e)}",
        )


@router.patch(
    "/admin/models/{model_id}/toggle", dependencies=[Depends(get_current_admin_user)]
)
async def toggle_model_activation(
    model_id: str, is_active: bool, db: Session = Depends(get_db)
):
    """
    Admin endpoint to enable/disable a model.
    Useful for rapid mitigation of outages or cost control.
    """
    try:
        gateway = get_llm_gateway()

        success = await gateway.admin_toggle_model(model_id, is_active)

        if success:
            status_text = "activated" if is_active else "deactivated"
            return {"message": f"Model {model_id} {status_text} successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Model {model_id} not found",
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to toggle model: {str(e)}",
        )


@router.post("/admin/routing-rules", dependencies=[Depends(get_current_admin_user)])
async def add_routing_rule(request: RoutingRuleRequest, db: Session = Depends(get_db)):
    """
    Admin endpoint to add custom routing rules.
    Enables context-aware model selection.
    """
    try:
        gateway = get_llm_gateway()

        routing_rule = RoutingRule(
            rule_id=request.rule_id,
            name=request.name,
            conditions=request.conditions,
            target_models=request.target_models,
            weight=request.weight,
            is_active=request.is_active,
        )

        success = await gateway.config_manager.add_routing_rule(routing_rule)

        if success:
            return {"message": f"Routing rule {request.rule_id} added successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to add routing rule",
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add routing rule: {str(e)}",
        )


@router.post("/admin/ab-tests", dependencies=[Depends(get_current_admin_user)])
async def create_ab_test(request: ABTestRequest, db: Session = Depends(get_db)):
    """
    Admin endpoint to create A/B tests for model comparison.
    Enables data-driven model selection optimization.
    """
    try:
        gateway = get_llm_gateway()

        ab_test = ABTestConfiguration(
            test_id=request.test_id,
            name=request.name,
            description=request.description,
            is_active=True,
            start_date=request.start_date,
            end_date=request.end_date,
            traffic_split=request.traffic_split,
            model_variants=request.model_variants,
            success_metrics=request.success_metrics,
        )

        success = await gateway.config_manager.create_ab_test(ab_test)

        if success:
            return {"message": f"A/B test {request.test_id} created successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to create A/B test",
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create A/B test: {str(e)}",
        )


@router.post("/admin/budgets", dependencies=[Depends(get_current_admin_user)])
async def create_budget_configuration(
    request: BudgetConfigRequest, db: Session = Depends(get_db)
):
    """
    Admin endpoint to create budget configurations.
    Enables cost control and automated actions.
    """
    try:
        gateway = get_llm_gateway()

        budget_config = BudgetConfiguration(
            budget_id=request.budget_id,
            name=request.name,
            total_budget=request.total_budget,
            reset_period=BudgetResetPeriod(request.reset_period),
            alert_thresholds=request.alert_thresholds,
            auto_disable_at_limit=request.auto_disable_at_limit,
            user_groups=request.user_groups,
        )

        success = await gateway.config_manager.create_budget(budget_config)

        if success:
            return {"message": f"Budget {request.budget_id} created successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to create budget configuration",
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create budget: {str(e)}",
        )


@router.get(
    "/admin/analytics/usage-report", dependencies=[Depends(get_current_admin_user)]
)
async def get_usage_report(
    start_date: datetime,
    end_date: datetime,
    user_id: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """
    Admin endpoint to generate comprehensive usage reports.
    Provides detailed analytics for optimization and billing.
    """
    try:
        gateway = get_llm_gateway()

        report = await gateway.analytics.get_usage_report(
            start_date=start_date, end_date=end_date, user_id=user_id
        )

        return report

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate usage report: {str(e)}",
        )


@router.get("/admin/models", dependencies=[Depends(get_current_admin_user)])
async def list_model_configurations(db: Session = Depends(get_db)):
    """
    Admin endpoint to list all model configurations.
    Shows current status, health, and settings.
    """
    try:
        gateway = get_llm_gateway()

        active_models = gateway.config_manager.get_active_models()
        all_models = list(gateway.config_manager.models.values())

        model_list = []
        for model in all_models:
            # Get health status if adapter exists
            health_status = None
            if model.model_id in gateway.adapters:
                adapter = gateway.adapters[model.model_id]
                health_status = adapter.get_health_status()

            model_info = {
                "model_id": model.model_id,
                "provider": model.provider,
                "model_name": model.model_name,
                "is_active": model.is_active,
                "priority": model.priority.value,
                "cost_per_token": model.cost_per_token,
                "max_tokens": model.max_tokens,
                "health_status": (
                    {
                        "is_healthy": (
                            health_status.is_healthy if health_status else False
                        ),
                        "latency_ms": (
                            health_status.latency_ms if health_status else None
                        ),
                        "last_check": (
                            health_status.last_check if health_status else None
                        ),
                        "error_message": (
                            health_status.error_message if health_status else None
                        ),
                    }
                    if health_status
                    else None
                ),
            }
            model_list.append(model_info)

        return {
            "total_models": len(all_models),
            "active_models": len(active_models),
            "models": model_list,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to list models: {str(e)}",
        )


@router.get("/admin/config/export", dependencies=[Depends(get_current_admin_user)])
async def export_configuration(db: Session = Depends(get_db)):
    """
    Admin endpoint to export complete system configuration.
    Useful for backup, migration, and audit purposes.
    """
    try:
        gateway = get_llm_gateway()

        config_export = gateway.config_manager.export_configuration()

        return {
            "export_timestamp": datetime.utcnow().isoformat(),
            "configuration": config_export,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to export configuration: {str(e)}",
        )
