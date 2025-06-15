from __future__ import annotations

import os
from celery import Celery

CELERY_BROKER_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
CELERY_BACKEND_URL = CELERY_BROKER_URL

celery_app = Celery("vigor", broker=CELERY_BROKER_URL, backend=CELERY_BACKEND_URL)
celery_app.conf.update(task_serializer="json", result_serializer="json", accept_content=["json"], timezone="UTC")
