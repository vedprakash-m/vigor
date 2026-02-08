"""
Vigor Backend - Azure Functions App
Phase 7.1.5: Blueprint-based modular architecture

Single resource group (vigor-rg), Cosmos DB Serverless, Azure OpenAI gpt-5-mini
Production domain: vigor.vedprakash.net

Blueprint modules:
  - blueprints/auth_bp.py     → auth/me, users/profile
  - blueprints/workouts_bp.py → workouts/*, workout generation & history
  - blueprints/coach_bp.py    → coach/chat, coach/history
  - blueprints/ghost_bp.py    → ghost/*, timer triggers
  - blueprints/admin_bp.py    → admin/* (email-whitelisted)
  - blueprints/health_bp.py   → health, health-simple
"""

import logging

import azure.functions as func

from blueprints.admin_bp import admin_bp
from blueprints.auth_bp import auth_bp
from blueprints.coach_bp import coach_bp
from blueprints.ghost_bp import ghost_bp
from blueprints.health_bp import health_bp
from blueprints.workouts_bp import workouts_bp
from shared.config import get_settings

# Initialize settings early so validation runs at startup
settings = get_settings()

# Create Function App
app = func.FunctionApp()

# Configure logging
logging.basicConfig(level=getattr(logging, settings.LOG_LEVEL))
logger = logging.getLogger(__name__)

# =============================================================================
# Register Blueprints
# =============================================================================

app.register_functions(auth_bp)
app.register_functions(workouts_bp)
app.register_functions(coach_bp)
app.register_functions(ghost_bp)
app.register_functions(admin_bp)
app.register_functions(health_bp)

logger.info("Vigor Function App initialized with Blueprint modules")
