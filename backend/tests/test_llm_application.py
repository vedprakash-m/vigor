import pytest

from core.llm_orchestration.adapters import LLMRequest, LLMResponse
from core.llm_orchestration.gateway import GatewayRequest

from application.llm.request_validator import RequestValidator
from application.llm.budget_enforcer import BudgetEnforcer

from types import SimpleNamespace

from application.llm.routing_engine import RoutingEngine
from application.llm.response_recorder import ResponseRecorder


class DummyBudgetManager:
    def __init__(self, allow: bool = True):
        self._allow = allow

    async def can_proceed(self, *_args, **_kwargs):  # noqa: D401
        return self._allow


@pytest.mark.asyncio
async def test_request_validator_enriches():
    validator = RequestValidator()
    gw_req = GatewayRequest(prompt="Hello", user_id="u1")
    enriched = validator(gw_req, "req-123")

    assert isinstance(enriched, LLMRequest)
    assert enriched.prompt == "Hello"
    assert enriched.context["request_id"] == "req-123"
    assert enriched.context["timestamp"] is not None


@pytest.mark.asyncio
async def test_budget_enforcer_allows():
    enforcer = BudgetEnforcer(DummyBudgetManager(True))
    # Should not raise
    await enforcer.ensure_within_budget("u1", [])


@pytest.mark.asyncio
async def test_budget_enforcer_blocks():
    enforcer = BudgetEnforcer(DummyBudgetManager(False))
    with pytest.raises(Exception):
        await enforcer.ensure_within_budget("u1", [])


@pytest.mark.asyncio
async def test_routing_engine_delegates(monkeypatch):
    # Prepare dummy delegate returning 'foo-model'
    class DummyDelegate:
        async def select_model(self, context, candidates):  # noqa: D401
            self.last_context = context
            self.last_candidates = candidates
            return "foo-model"

    dummy_delegate = DummyDelegate()

    # Monkeypatch RoutingEngine to use dummy delegate
    engine = RoutingEngine.__new__(RoutingEngine)  # bypass __init__
    engine._delegate = dummy_delegate  # type: ignore

    chosen = await engine.select_model({"k": "v"}, ["foo-model", "bar-model"])
    assert chosen == "foo-model"
    assert dummy_delegate.last_candidates == ["foo-model", "bar-model"]


@pytest.mark.asyncio
async def test_response_recorder_calls(monkeypatch):
    # Capture calls via lists
    called = {
        "cache": False,
        "log": False,
        "budget": False,
        "analytics": False,
    }

    class DummyCache:
        async def set(self, *_):  # noqa: D401
            called["cache"] = True

    class DummyLogger:
        async def log_request(self, **_):  # noqa: D401
            called["log"] = True

    class DummyBudget:
        async def record_usage(self, *_):  # noqa: D401
            called["budget"] = True

    class DummyAnalytics:
        async def record_request(self, *_):  # noqa: D401
            called["analytics"] = True

    recorder = ResponseRecorder(
        DummyLogger(),
        DummyBudget(),
        DummyAnalytics(),
        DummyCache(),
    )

    gw_req = SimpleNamespace(
        user_id="u1",
        task_type="chat",
        session_id=None,
        user_tier="free",
    )

    llm_req = LLMRequest(prompt="hi")
    llm_resp = LLMResponse(
        content="ok",
        model_used="m",
        provider="p",
        tokens_used=1,
        cost_estimate=0.0,
        latency_ms=1,
    )

    await recorder.record("req-id", gw_req, llm_req, llm_resp)

    assert all(called.values())
