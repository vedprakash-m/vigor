"""
Performance monitoring and optimization utilities for Azure Functions
"""

import asyncio
import logging
import time
from typing import Any, Callable, Dict, Optional

logger = logging.getLogger(__name__)


class FunctionPerformanceMonitor:
    """Monitor and optimize Function App performance."""

    def __init__(self):
        """Initialize the performance monitor."""
        self.call_metrics: Dict[str, Dict[str, float]] = {}
        self.cold_starts: Dict[str, bool] = {}

        # Warmup status tracking
        self.last_warmup: Dict[str, float] = {}
        self.warmup_interval = 5 * 60  # 5 minutes

    async def monitor_call(
        self, function_name: str, call_func: Callable, *args: Any, **kwargs: Any
    ) -> Any:
        """
        Monitor a function call and collect performance metrics.
        Returns the result of the function call.
        """
        # Track if this is likely a cold start
        is_cold_start = function_name not in self.call_metrics
        if is_cold_start:
            self.cold_starts[function_name] = True
            logger.info(f"Potential cold start detected for function: {function_name}")

        # Measure call performance
        start_time = time.time()

        try:
            result = await call_func(*args, **kwargs)

            # Record metrics
            end_time = time.time()
            duration = end_time - start_time

            if function_name not in self.call_metrics:
                self.call_metrics[function_name] = {
                    "count": 1,
                    "total_time": duration,
                    "min_time": duration,
                    "max_time": duration,
                    "last_call_time": end_time,
                }
            else:
                metrics = self.call_metrics[function_name]
                metrics["count"] += 1
                metrics["total_time"] += duration
                metrics["min_time"] = min(metrics["min_time"], duration)
                metrics["max_time"] = max(metrics["max_time"], duration)
                metrics["last_call_time"] = end_time

            # Log performance data
            avg_time = (
                self.call_metrics[function_name]["total_time"]
                / self.call_metrics[function_name]["count"]
            )
            logger.info(
                f"Function {function_name} call completed in {duration:.2f}s (avg: {avg_time:.2f}s)"
            )

            # Cold start vs warm call tracking
            if is_cold_start:
                logger.info(f"Cold start time for {function_name}: {duration:.2f}s")

            return result

        except Exception as e:
            end_time = time.time()
            duration = end_time - start_time
            logger.error(
                f"Function {function_name} failed after {duration:.2f}s: {str(e)}"
            )
            raise

    async def keep_warm(
        self, warmup_func: Callable, function_name: str, interval: Optional[int] = None
    ) -> None:
        """
        Keep a function warm by calling it periodically.
        Should be run in a background task.
        """
        warmup_interval = interval or self.warmup_interval

        while True:
            current_time = time.time()
            last_call = self.call_metrics.get(function_name, {}).get(
                "last_call_time", 0
            )

            # Check if function needs warming up
            if current_time - last_call > warmup_interval:
                logger.info(f"Warming up function: {function_name}")
                try:
                    await warmup_func()
                    self.last_warmup[function_name] = time.time()
                except Exception as e:
                    logger.error(f"Error during warmup of {function_name}: {str(e)}")

            # Wait for next interval
            await asyncio.sleep(warmup_interval)

    def get_metrics(self, function_name: Optional[str] = None) -> Dict[str, Any]:
        """Get performance metrics for a specific function or all functions."""
        if function_name:
            if function_name in self.call_metrics:
                metrics = self.call_metrics[function_name].copy()
                metrics["avg_time"] = (
                    metrics["total_time"] / metrics["count"]
                    if metrics["count"] > 0
                    else 0
                )
                return metrics
            return {}

        # Return all metrics
        all_metrics = {}
        for name, metrics in self.call_metrics.items():
            func_metrics = metrics.copy()
            func_metrics["avg_time"] = (
                func_metrics["total_time"] / func_metrics["count"]
                if func_metrics["count"] > 0
                else 0
            )
            all_metrics[name] = func_metrics

        return all_metrics


# Create a global instance of the performance monitor
perf_monitor = FunctionPerformanceMonitor()
