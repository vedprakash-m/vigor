from __future__ import annotations

from datetime import timedelta

from infrastructure.tasks.celery_app import celery_app
from core.llm_orchestration_init import get_llm_gateway


@celery_app.on_after_configure.connect
def setup_periodic_tasks(sender, **_):  # noqa: D401
    # Health check every 5 minutes
    sender.add_periodic_task(300, health_check.s())


@celery_app.task
def health_check():  # noqa: D401
    from celery.utils.log import get_task_logger

    logger = get_task_logger(__name__)

    try:
        gateway = get_llm_gateway()
        status = gateway.is_initialized  # just to access
        logger.info("Gateway health OK: %s", status)
    except Exception as exc:  # pragma: no cover
        logger.error("Gateway health check failed: %s", exc)
