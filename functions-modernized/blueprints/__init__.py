"""
Vigor Blueprints Package
Phase 7.1.5: Modular decomposition of monolithic function_app.py

Each Blueprint registers a group of related endpoints:
  - auth_bp: Authentication & user management
  - workouts_bp: Workout CRUD & session logging
  - coach_bp: AI coach chat
  - ghost_bp: Ghost Engine APIs (trust, schedule, phenome, receipts, timers)
  - admin_bp: Admin-only dashboard APIs
  - health_bp: Health check endpoints
"""
