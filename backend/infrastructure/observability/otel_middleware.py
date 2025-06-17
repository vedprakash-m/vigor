from __future__ import annotations

"""FastAPI middleware that sets up OpenTelemetry tracing & logging."""

from typing import Callable

from fastapi import Request, Response
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from starlette.middleware.base import BaseHTTPMiddleware


class OTelMiddleware(BaseHTTPMiddleware):
    _initialized: bool = False

    def __init__(self, app, service_name: str = "vigor-backend") -> None:  # noqa: D401
        self._service_name = service_name
        if not OTelMiddleware._initialized:
            resource = Resource.create({"service.name": service_name})
            provider = TracerProvider(resource=resource)
            processor = BatchSpanProcessor(OTLPSpanExporter())
            provider.add_span_processor(processor)
            trace.set_tracer_provider(provider)
            OTelMiddleware._initialized = True
        super().__init__(app)

    async def dispatch(
        self, request: Request, call_next: Callable[[Request], Response]
    ):  # noqa: D401
        tracer = trace.get_tracer("vigor.middleware")
        with tracer.start_as_current_span(request.url.path):
            response = await call_next(request)
        return response
