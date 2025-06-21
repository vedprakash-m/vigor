"""
Circuit Breaker Manager
Implements circuit breaker pattern for LLM provider resilience
"""

import logging
import time
from dataclasses import dataclass
from enum import Enum
from typing import Optional

logger = logging.getLogger(__name__)


class CircuitState(Enum):
    """Circuit breaker states"""

    CLOSED = "closed"  # Normal operation
    OPEN = "open"  # Failing, blocking requests
    HALF_OPEN = "half_open"  # Testing if service recovered


@dataclass
class CircuitBreakerConfig:
    """Circuit breaker configuration"""

    failure_threshold: int = 5
    recovery_timeout: int = 60  # seconds
    half_open_max_calls: int = 3


@dataclass
class CircuitBreakerState:
    """Circuit breaker state tracking"""

    state: CircuitState
    failure_count: int
    last_failure_time: float
    half_open_calls: int
    config: CircuitBreakerConfig


class CircuitBreakerManager:
    """
    Circuit breaker manager for LLM providers
    Prevents cascade failures and enables graceful degradation
    """

    def __init__(self):
        self._circuits: dict[str, CircuitBreakerState] = {}
        self._default_config = CircuitBreakerConfig()

    async def initialize(self, model_ids: list):
        """Initialize circuit breakers for models"""
        for model_id in model_ids:
            self.add_model(model_id)
        logger.info(f"Initialized circuit breakers for {len(model_ids)} models")

    def add_model(self, model_id: str, config: Optional[CircuitBreakerConfig] = None):
        """Add circuit breaker for a model"""
        self._circuits[model_id] = CircuitBreakerState(
            state=CircuitState.CLOSED,
            failure_count=0,
            last_failure_time=0,
            half_open_calls=0,
            config=config or self._default_config,
        )

    def remove_model(self, model_id: str):
        """Remove circuit breaker for a model"""
        if model_id in self._circuits:
            del self._circuits[model_id]

    def can_proceed(self, model_id: str) -> bool:
        """Check if requests can proceed for a model"""
        if model_id not in self._circuits:
            return True

        circuit = self._circuits[model_id]
        current_time = time.time()

        if circuit.state == CircuitState.CLOSED:
            return True

        elif circuit.state == CircuitState.OPEN:
            # Check if recovery timeout has passed
            if (
                current_time - circuit.last_failure_time
                >= circuit.config.recovery_timeout
            ):
                circuit.state = CircuitState.HALF_OPEN
                circuit.half_open_calls = 0
                logger.info(f"Circuit breaker for {model_id} moved to HALF_OPEN")
                return True
            return False

        elif circuit.state == CircuitState.HALF_OPEN:
            return circuit.half_open_calls < circuit.config.half_open_max_calls

    def record_success(self, model_id: str):
        """Record a successful request"""
        if model_id not in self._circuits:
            return

        circuit = self._circuits[model_id]

        if circuit.state == CircuitState.HALF_OPEN:
            circuit.half_open_calls += 1

            # If enough successful calls, close the circuit
            if circuit.half_open_calls >= circuit.config.half_open_max_calls:
                circuit.state = CircuitState.CLOSED
                circuit.failure_count = 0
                circuit.half_open_calls = 0
                logger.info(f"Circuit breaker for {model_id} CLOSED (recovered)")

        elif circuit.state == CircuitState.CLOSED:
            # Reset failure count on success
            circuit.failure_count = max(0, circuit.failure_count - 1)

    def record_failure(self, model_id: str):
        """Record a failed request"""
        if model_id not in self._circuits:
            return

        circuit = self._circuits[model_id]
        circuit.failure_count += 1
        circuit.last_failure_time = time.time()

        if circuit.state == CircuitState.HALF_OPEN:
            # Failure during half-open, go back to open
            circuit.state = CircuitState.OPEN
            circuit.half_open_calls = 0
            logger.warning(f"Circuit breaker for {model_id} reopened due to failure")

        elif circuit.state == CircuitState.CLOSED:
            # Check if we should open the circuit
            if circuit.failure_count >= circuit.config.failure_threshold:
                circuit.state = CircuitState.OPEN
                logger.warning(
                    f"Circuit breaker for {model_id} OPENED due to {circuit.failure_count} failures"
                )

    def get_status(self) -> dict[str, dict]:
        """Get status of all circuit breakers"""
        status = {}
        for model_id, circuit in self._circuits.items():
            status[model_id] = {
                "state": circuit.state.value,
                "failure_count": circuit.failure_count,
                "last_failure_time": circuit.last_failure_time,
                "half_open_calls": circuit.half_open_calls,
            }
        return status

    def get_healthy_models(self) -> set[str]:
        """Get set of models that can accept requests"""
        healthy = set()
        for model_id in self._circuits:
            if self.can_proceed(model_id):
                healthy.add(model_id)
        return healthy
