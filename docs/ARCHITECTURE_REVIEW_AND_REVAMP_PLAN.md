# Vigor Architecture Review & Production Revamp Plan

**Version**: 2.0  
**Date**: January 19, 2026  
**Author**: Architecture Review  
**Status**: Comprehensive Migration Plan - Ready for Execution

---

## Executive Summary

This document provides a comprehensive plan to transform Vigor from a fragmented prototype into a **production-ready, cost-efficient fitness application**. The architecture prioritizes:

- **Cost Efficiency**: Target ≤$40/month operational cost
- **Simplicity**: Single environment, single resource group, minimal complexity
- **Reliability**: Azure-native services with built-in redundancy
- **Security**: Microsoft Entra ID default tenant authentication

### Target Architecture

| Component  | Technology           | Tier/Plan        | Est. Monthly Cost |
| ---------- | -------------------- | ---------------- | ----------------- |
| Frontend   | Azure Static Web App | Free             | $0                |
| Backend    | Azure Functions      | Flex Consumption | $5-15             |
| Database   | Cosmos DB            | Serverless       | $5-20             |
| AI         | OpenAI gpt-5-mini    | Pay-per-token    | $5-15             |
| Secrets    | Azure Key Vault      | Standard         | ~$1               |
| Monitoring | Application Insights | Free (5GB)       | $0                |
| **Total**  |                      |                  | **$16-51/month**  |

### Resource Naming Convention

All resources in **`vigor-rg`** (West US 2):

| Resource Type     | Name             |
| ----------------- | ---------------- |
| Resource Group    | `vigor-rg`       |
| Function App      | `vigor-func`     |
| Static Web App    | `vigor-web`      |
| Cosmos DB Account | `vigor-cosmos`   |
| Key Vault         | `vigor-kv`       |
| Storage Account   | `vigorsa`        |
| App Insights      | `vigor-insights` |
| Log Analytics     | `vigor-logs`     |

---

## Part 1: Current State Analysis

### 1.1 The Three-System Problem (To Be Resolved)

The codebase currently has **three separate backend implementations**:

| System                     | Location                | Status              | Action                                   |
| -------------------------- | ----------------------- | ------------------- | ---------------------------------------- |
| FastAPI Backend            | `/backend`              | Most complete code  | **Archive** - Port services to Functions |
| Azure Functions Original   | `/functions`            | Abandoned           | **Archived** ✅                          |
| Azure Functions Modernized | `/functions-modernized` | Aligned with target | **Keep** - Enhance                       |

### 1.2 Critical Issues to Resolve

| Issue                                       | Severity | Resolution                  |
| ------------------------------------------- | -------- | --------------------------- |
| Hardcoded `localhost:8001` URLs in frontend | Critical | Replace with API service    |
| Three backend implementations               | Critical | Consolidate to Functions    |
| PostgreSQL + Cosmos DB dual system          | Critical | Cosmos DB only              |
| Over-engineered LLM orchestration           | Medium   | Simplify to single provider |
| VedUser custom auth complexity              | Medium   | Use Entra ID default tenant |
| 8% frontend test coverage                   | High     | Target 80%                  |
| Duplicate `-temp.tsx` files                 | Low      | **Archived** ✅             |

---

## Part 2: Target Architecture

### 2.1 System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              vigor-rg (West US 2)                           │
│                                                                             │
│  ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐     │
│  │  vigor-web      │      │  vigor-func     │      │  vigor-cosmos   │     │
│  │  Static Web App │─────▶│  Functions      │─────▶│  Cosmos DB      │     │
│  │  (React SPA)    │      │  (Flex Consump) │      │  (Serverless)   │     │
│  └─────────────────┘      └─────────────────┘      └─────────────────┘     │
│          │                        │                        │               │
│          │                        │                        │               │
│          ▼                        ▼                        ▼               │
│  ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐     │
│  │  Microsoft      │      │  OpenAI API     │      │  vigor-kv       │     │
│  │  Entra ID       │      │  (gpt-5-mini)   │      │  Key Vault      │     │
│  │  (Default)      │      │                 │      │                 │     │
│  └─────────────────┘      └─────────────────┘      └─────────────────┘     │
│                                   │                                        │
│                                   ▼                                        │
│                           ┌─────────────────┐                              │
│                           │  vigor-insights │                              │
│                           │  App Insights   │                              │
│                           └─────────────────┘                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Authentication Flow (Simplified)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   User       │     │  vigor-web   │     │  Entra ID    │     │  vigor-func  │
│   Browser    │     │  (SPA)       │     │  (Default)   │     │  (API)       │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │                    │
       │  1. Visit App      │                    │                    │
       │───────────────────▶│                    │                    │
       │                    │                    │                    │
       │  2. Click Login    │                    │                    │
       │───────────────────▶│                    │                    │
       │                    │  3. Redirect       │                    │
       │                    │───────────────────▶│                    │
       │                    │                    │                    │
       │  4. Enter Microsoft credentials         │                    │
       │────────────────────────────────────────▶│                    │
       │                    │                    │                    │
       │                    │  5. Return tokens  │                    │
       │◀────────────────────────────────────────│                    │
       │                    │                    │                    │
       │                    │  6. API call + Bearer token             │
       │                    │────────────────────────────────────────▶│
       │                    │                    │                    │
       │                    │                    │  7. Validate token │
       │                    │                    │◀───────────────────│
       │                    │                    │                    │
       │                    │  8. Response       │                    │
       │◀────────────────────────────────────────────────────────────│
       │                    │                    │                    │
```

**Key Authentication Decisions:**

1. **Provider**: Microsoft Entra ID (default tenant - `common`)
2. **Flow**: MSAL.js with PKCE (SPA flow)
3. **Token Validation**: Azure Functions validates JWT on each request
4. **User Creation**: Auto-create user profile on first login
5. **No Custom Claims**: Use standard Entra ID claims (email, name, oid)

### 2.3 Database Schema (Cosmos DB)

**Database**: `vigor-db`

**Containers**:

```javascript
// Container: users
// Partition Key: /id (user's Entra ID object ID)
{
  "id": "abc123-def456",           // Entra ID oid
  "email": "user@outlook.com",
  "displayName": "John Doe",
  "profile": {
    "fitnessLevel": "beginner",    // beginner, intermediate, advanced
    "goals": ["weight_loss", "strength"],
    "equipment": ["dumbbells", "resistance_bands"],
    "preferredDuration": 45
  },
  "tier": "free",                  // free, premium
  "stats": {
    "totalWorkouts": 42,
    "currentStreak": 7,
    "longestStreak": 21
  },
  "createdAt": "2026-01-19T10:00:00Z",
  "updatedAt": "2026-01-19T10:00:00Z"
}

// Container: workouts
// Partition Key: /userId
{
  "id": "workout-uuid",
  "userId": "abc123-def456",
  "name": "Full Body Strength",
  "description": "Complete upper and lower body workout",
  "exercises": [
    {
      "name": "Squats",
      "sets": 3,
      "reps": "12",
      "rest": "60s",
      "notes": "Keep knees over toes"
    }
  ],
  "durationMinutes": 45,
  "difficulty": "intermediate",
  "equipment": ["dumbbells"],
  "aiGenerated": true,
  "createdAt": "2026-01-19T10:00:00Z"
}

// Container: workout-logs
// Partition Key: /userId
{
  "id": "log-uuid",
  "userId": "abc123-def456",
  "workoutId": "workout-uuid",
  "completedAt": "2026-01-19T11:00:00Z",
  "actualDuration": 48,
  "rating": 4,
  "notes": "Felt strong today",
  "exercisesCompleted": [
    {
      "name": "Squats",
      "setsCompleted": 3,
      "repsAchieved": [12, 12, 10]
    }
  ]
}

// Container: coach-messages
// Partition Key: /userId
// TTL: 2592000 (30 days)
{
  "id": "msg-uuid",
  "userId": "abc123-def456",
  "role": "user",                  // user, assistant
  "content": "How do I improve my squat form?",
  "timestamp": "2026-01-19T10:30:00Z",
  "ttl": 2592000
}
```

---

## Part 3: Migration Plan

### Phase 0: Cleanup & Preparation (Week 1)

**Goal**: Clean slate, remove dead code, fix blocking issues

#### Task 0.1: Archive Redundant Files ✅ DONE

```
Moved to .archive/:
├── functions/              # Abandoned original functions → .archive/functions-abandoned
├── infrastructure/bicep/   # Old bicep files → .archive/bicep-old/
│   ├── app-service.bicep
│   ├── cost-optimized.bicep
│   ├── db.bicep
│   ├── function-app.bicep
│   ├── function-app-y1.bicep
│   ├── main.bicep
│   ├── main.json
│   └── storage.bicep
└── frontend/src/components/ → .archive/frontend-temp-components/
    ├── AnalyticsDashboard-temp.tsx
    └── CommunityFeatures-temp.tsx
```

#### Task 0.2: Fix Critical Frontend Issues

| File              | Issue                      | Fix               |
| ----------------- | -------------------------- | ----------------- |
| `WorkoutPage.tsx` | Hardcoded `localhost:8001` | Use API service   |
| `CoachPage.tsx`   | Hardcoded `localhost:8001` | Use API service   |
| `WorkoutPage.tsx` | Native `<select>` element  | Use Chakra Select |

#### Task 0.3: Simplify Auth Configuration

Update `frontend/src/config/authConfig.ts`:

```typescript
export const msalConfig = {
  auth: {
    clientId: import.meta.env.VITE_AZURE_CLIENT_ID,
    authority: "https://login.microsoftonline.com/common", // Default tenant
    redirectUri: import.meta.env.VITE_REDIRECT_URI || window.location.origin,
  },
  cache: {
    cacheLocation: "sessionStorage",
    storeAuthStateInCookie: false,
  },
};

export const loginRequest = {
  scopes: ["openid", "profile", "email"],
};
```

---

### Phase 1: Backend Consolidation (Weeks 2-3)

**Goal**: Single Azure Functions backend with all features

#### Task 1.1: Final Functions Structure

```
functions-modernized/
├── function_app.py              # Main entry point
├── host.json                    # Function host config
├── local.settings.json          # Local dev settings
├── requirements.txt             # Python dependencies
├── shared/
│   ├── __init__.py
│   ├── config.py                # Settings from environment
│   ├── auth.py                  # Entra ID token validation
│   ├── cosmos_client.py         # Cosmos DB operations
│   ├── openai_client.py         # OpenAI gpt-5-mini integration
│   ├── models.py                # Pydantic models
│   └── middleware.py            # Rate limiting, logging
└── tests/
    ├── conftest.py
    ├── test_auth.py
    ├── test_workouts.py
    └── test_coach.py
```

#### Task 1.2: Implement Core Functions

```python
# function_app.py - Complete implementation

import azure.functions as func
import json
import logging
from datetime import datetime
from shared.auth import get_user_from_token
from shared.cosmos_client import CosmosClient
from shared.openai_client import OpenAIClient
from shared.config import Settings
from shared.middleware import rate_limit

app = func.FunctionApp()
settings = Settings()
cosmos = CosmosClient()
openai = OpenAIClient()

# =============================================================================
# AUTHENTICATION
# =============================================================================

@app.route(route="auth/me", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def get_current_user(req: func.HttpRequest) -> func.HttpResponse:
    """Get current user from Entra ID token"""
    try:
        user = await get_user_from_token(req)
        if not user:
            return func.HttpResponse(
                json.dumps({"error": "Unauthorized"}),
                status_code=401,
                mimetype="application/json"
            )

        # Get or create user profile
        profile = await cosmos.get_or_create_user(user)
        return func.HttpResponse(
            json.dumps(profile),
            status_code=200,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f"Auth error: {e}")
        return func.HttpResponse(
            json.dumps({"error": "Internal error"}),
            status_code=500,
            mimetype="application/json"
        )

# =============================================================================
# USER PROFILE
# =============================================================================

@app.route(route="users/profile", methods=["GET", "PUT"], auth_level=func.AuthLevel.ANONYMOUS)
async def user_profile(req: func.HttpRequest) -> func.HttpResponse:
    """Get or update user profile"""
    user = await get_user_from_token(req)
    if not user:
        return func.HttpResponse(json.dumps({"error": "Unauthorized"}), status_code=401)

    if req.method == "GET":
        profile = await cosmos.get_user(user["oid"])
        return func.HttpResponse(json.dumps(profile), mimetype="application/json")

    elif req.method == "PUT":
        data = req.get_json()
        updated = await cosmos.update_user(user["oid"], data)
        return func.HttpResponse(json.dumps(updated), mimetype="application/json")

# =============================================================================
# WORKOUT GENERATION
# =============================================================================

@app.route(route="workouts/generate", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def generate_workout(req: func.HttpRequest) -> func.HttpResponse:
    """Generate workout using OpenAI gpt-5-mini"""
    user = await get_user_from_token(req)
    if not user:
        return func.HttpResponse(json.dumps({"error": "Unauthorized"}), status_code=401)

    # Rate limit: 20 generations per hour
    if not await rate_limit(f"workout:{user['oid']}", limit=20, window=3600):
        return func.HttpResponse(
            json.dumps({"error": "Rate limit exceeded"}),
            status_code=429
        )

    try:
        params = req.get_json()
        profile = await cosmos.get_user(user["oid"])

        # Generate with OpenAI
        workout = await openai.generate_workout(
            fitness_level=profile.get("profile", {}).get("fitnessLevel", "beginner"),
            goals=profile.get("profile", {}).get("goals", []),
            equipment=params.get("equipment", []),
            duration=params.get("durationMinutes", 45),
            focus_areas=params.get("focusAreas", [])
        )

        # Save to Cosmos
        saved = await cosmos.create_workout(user["oid"], workout)

        return func.HttpResponse(
            json.dumps(saved),
            status_code=201,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f"Workout generation error: {e}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to generate workout"}),
            status_code=500
        )

@app.route(route="workouts", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def list_workouts(req: func.HttpRequest) -> func.HttpResponse:
    """List user's workouts"""
    user = await get_user_from_token(req)
    if not user:
        return func.HttpResponse(json.dumps({"error": "Unauthorized"}), status_code=401)

    limit = int(req.params.get("limit", 20))
    workouts = await cosmos.list_workouts(user["oid"], limit)
    return func.HttpResponse(json.dumps(workouts), mimetype="application/json")

@app.route(route="workouts/log", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def log_workout(req: func.HttpRequest) -> func.HttpResponse:
    """Log completed workout"""
    user = await get_user_from_token(req)
    if not user:
        return func.HttpResponse(json.dumps({"error": "Unauthorized"}), status_code=401)

    data = req.get_json()
    log = await cosmos.create_workout_log(user["oid"], data)

    # Update user stats
    await cosmos.update_user_stats(user["oid"])

    return func.HttpResponse(json.dumps(log), status_code=201, mimetype="application/json")

# =============================================================================
# AI COACH
# =============================================================================

@app.route(route="coach/chat", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
async def coach_chat(req: func.HttpRequest) -> func.HttpResponse:
    """Chat with AI coach"""
    user = await get_user_from_token(req)
    if not user:
        return func.HttpResponse(json.dumps({"error": "Unauthorized"}), status_code=401)

    # Rate limit: 50 messages per hour
    if not await rate_limit(f"coach:{user['oid']}", limit=50, window=3600):
        return func.HttpResponse(json.dumps({"error": "Rate limit exceeded"}), status_code=429)

    try:
        data = req.get_json()
        message = data.get("message", "")

        # Get conversation history
        history = await cosmos.get_coach_history(user["oid"], limit=10)
        profile = await cosmos.get_user(user["oid"])

        # Generate response
        response = await openai.coach_chat(
            message=message,
            history=history,
            user_context=profile
        )

        # Save messages
        await cosmos.save_coach_message(user["oid"], "user", message)
        await cosmos.save_coach_message(user["oid"], "assistant", response)

        return func.HttpResponse(
            json.dumps({"response": response}),
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f"Coach chat error: {e}")
        return func.HttpResponse(
            json.dumps({"error": "Failed to get response"}),
            status_code=500
        )

@app.route(route="coach/history", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def coach_history(req: func.HttpRequest) -> func.HttpResponse:
    """Get coach conversation history"""
    user = await get_user_from_token(req)
    if not user:
        return func.HttpResponse(json.dumps({"error": "Unauthorized"}), status_code=401)

    limit = int(req.params.get("limit", 50))
    history = await cosmos.get_coach_history(user["oid"], limit)
    return func.HttpResponse(json.dumps(history), mimetype="application/json")

# =============================================================================
# HEALTH & DIAGNOSTICS
# =============================================================================

@app.route(route="health", methods=["GET"], auth_level=func.AuthLevel.ANONYMOUS)
async def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint"""
    return func.HttpResponse(
        json.dumps({
            "status": "healthy",
            "version": "2.0.0",
            "timestamp": datetime.utcnow().isoformat()
        }),
        mimetype="application/json"
    )
```

#### Task 1.3: Implement OpenAI Client

```python
# shared/openai_client.py

import json
import openai
from .config import Settings

class OpenAIClient:
    def __init__(self):
        self.settings = Settings()
        self.client = openai.AsyncOpenAI(api_key=self.settings.OPENAI_API_KEY)
        self.model = "gpt-5-mini"

    async def generate_workout(
        self,
        fitness_level: str,
        goals: list[str],
        equipment: list[str],
        duration: int,
        focus_areas: list[str]
    ) -> dict:
        """Generate personalized workout plan"""

        prompt = f"""Create a {duration}-minute workout plan for a {fitness_level} fitness level user.

Goals: {', '.join(goals) if goals else 'General fitness'}
Available Equipment: {', '.join(equipment) if equipment else 'Bodyweight only'}
Focus Areas: {', '.join(focus_areas) if focus_areas else 'Full body'}

Return a JSON object with this structure:
{{
  "name": "Workout name",
  "description": "Brief description",
  "exercises": [
    {{
      "name": "Exercise name",
      "sets": 3,
      "reps": "12",
      "rest": "60s",
      "notes": "Form tips"
    }}
  ],
  "warmup": "5 min warmup description",
  "cooldown": "5 min cooldown description",
  "tips": ["Tip 1", "Tip 2"]
}}

Ensure exercises are appropriate for the fitness level and use only available equipment.
Include proper warmup and cooldown. Prioritize safety."""

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "You are an expert fitness coach. Always prioritize safety and proper form. Return only valid JSON."},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"},
            max_tokens=2000,
            temperature=0.7
        )

        return json.loads(response.choices[0].message.content)

    async def coach_chat(
        self,
        message: str,
        history: list[dict],
        user_context: dict
    ) -> str:
        """Generate coach response"""

        system_prompt = f"""You are a friendly, knowledgeable AI fitness coach.

User Profile:
- Fitness Level: {user_context.get('profile', {}).get('fitnessLevel', 'beginner')}
- Goals: {user_context.get('profile', {}).get('goals', [])}
- Equipment: {user_context.get('profile', {}).get('equipment', [])}

Guidelines:
1. Be encouraging and supportive
2. Provide actionable advice
3. Prioritize safety - recommend consulting a doctor for medical concerns
4. Keep responses concise but helpful
5. Reference the user's profile when relevant"""

        messages = [{"role": "system", "content": system_prompt}]

        # Add history
        for msg in history[-10:]:
            messages.append({"role": msg["role"], "content": msg["content"]})

        messages.append({"role": "user", "content": message})

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=messages,
            max_tokens=500,
            temperature=0.8
        )

        return response.choices[0].message.content
```

#### Task 1.4: Implement Auth Module

```python
# shared/auth.py

import jwt
import httpx
from functools import lru_cache
from azure.functions import HttpRequest
from .config import Settings

settings = Settings()

# Cache JWKS for 1 hour
@lru_cache(maxsize=1)
def get_jwks():
    """Fetch Microsoft JWKS for token validation"""
    response = httpx.get(
        "https://login.microsoftonline.com/common/discovery/v2.0/keys"
    )
    return response.json()

async def get_user_from_token(req: HttpRequest) -> dict | None:
    """Extract and validate user from Entra ID token"""

    auth_header = req.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return None

    token = auth_header[7:]

    try:
        # Decode without verification first to get header
        unverified = jwt.decode(token, options={"verify_signature": False})

        # Get the key ID from token header
        header = jwt.get_unverified_header(token)
        kid = header.get("kid")

        # Find matching key in JWKS
        jwks = get_jwks()
        key = None
        for k in jwks.get("keys", []):
            if k.get("kid") == kid:
                key = jwt.algorithms.RSAAlgorithm.from_jwk(k)
                break

        if not key:
            return None

        # Validate token
        payload = jwt.decode(
            token,
            key=key,
            algorithms=["RS256"],
            audience=settings.AZURE_CLIENT_ID,
            options={"verify_exp": True}
        )

        return {
            "oid": payload.get("oid"),  # Object ID - unique user identifier
            "email": payload.get("preferred_username") or payload.get("email"),
            "name": payload.get("name"),
            "given_name": payload.get("given_name"),
            "family_name": payload.get("family_name"),
        }

    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
    except Exception:
        return None
```

---

### Phase 2: Frontend Modernization (Weeks 3-4)

**Goal**: Clean, unified frontend with proper API integration

#### Task 2.1: Create Unified API Service

```typescript
// src/services/api.ts

import axios, { AxiosInstance, AxiosError } from "axios";

const API_BASE_URL = import.meta.env.VITE_API_URL || "";

class VigorAPI {
  private client: AxiosInstance;
  private accessToken: string | null = null;

  constructor() {
    this.client = axios.create({
      baseURL: API_BASE_URL,
      timeout: 30000,
      headers: {
        "Content-Type": "application/json",
      },
    });

    // Add auth token to all requests
    this.client.interceptors.request.use((config) => {
      if (this.accessToken) {
        config.headers.Authorization = `Bearer ${this.accessToken}`;
      }
      return config;
    });

    // Handle errors globally
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        if (error.response?.status === 401) {
          // Token expired - trigger re-auth
          window.dispatchEvent(new CustomEvent("auth:expired"));
        }
        return Promise.reject(error);
      },
    );
  }

  setAccessToken(token: string | null) {
    this.accessToken = token;
  }

  // Auth endpoints
  auth = {
    me: () => this.client.get("/api/auth/me"),
  };

  // User endpoints
  users = {
    getProfile: () => this.client.get("/api/users/profile"),
    updateProfile: (data: UserProfileUpdate) =>
      this.client.put("/api/users/profile", data),
  };

  // Workout endpoints
  workouts = {
    generate: (params: GenerateWorkoutParams) =>
      this.client.post<Workout>("/api/workouts/generate", params),
    list: (limit = 20) =>
      this.client.get<Workout[]>(`/api/workouts?limit=${limit}`),
    log: (data: WorkoutLogData) => this.client.post("/api/workouts/log", data),
  };

  // Coach endpoints
  coach = {
    chat: (message: string) =>
      this.client.post<{ response: string }>("/api/coach/chat", { message }),
    history: (limit = 50) =>
      this.client.get<ChatMessage[]>(`/api/coach/history?limit=${limit}`),
  };

  // Health
  health = {
    check: () => this.client.get("/api/health"),
  };
}

export const api = new VigorAPI();

// Types
export interface UserProfileUpdate {
  profile?: {
    fitnessLevel?: "beginner" | "intermediate" | "advanced";
    goals?: string[];
    equipment?: string[];
    preferredDuration?: number;
  };
}

export interface GenerateWorkoutParams {
  durationMinutes?: number;
  equipment?: string[];
  focusAreas?: string[];
}

export interface Workout {
  id: string;
  name: string;
  description: string;
  exercises: Exercise[];
  durationMinutes: number;
  difficulty: string;
  equipment: string[];
  createdAt: string;
}

export interface Exercise {
  name: string;
  sets: number;
  reps: string;
  rest: string;
  notes?: string;
}

export interface WorkoutLogData {
  workoutId: string;
  actualDuration: number;
  rating?: number;
  notes?: string;
  exercisesCompleted: {
    name: string;
    setsCompleted: number;
    repsAchieved: number[];
  }[];
}

export interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  timestamp: string;
}
```

#### Task 2.2: Simplify Auth Context

```typescript
// src/contexts/AuthContext.tsx

import {
  useAccount,
  useIsAuthenticated,
  useMsal,
} from '@azure/msal-react';
import { createContext, useContext, useEffect, useState } from 'react';
import { api } from '../services/api';
import { loginRequest } from '../config/authConfig';

interface User {
  id: string;
  email: string;
  name: string;
  profile?: {
    fitnessLevel: string;
    goals: string[];
    equipment: string[];
  };
  tier: string;
}

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: () => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { instance, accounts } = useMsal();
  const isAuthenticated = useIsAuthenticated();
  const account = useAccount(accounts[0] || {});
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const initAuth = async () => {
      if (isAuthenticated && account) {
        try {
          // Get token silently
          const response = await instance.acquireTokenSilent({
            ...loginRequest,
            account,
          });

          // Set token for API calls
          api.setAccessToken(response.accessToken);

          // Fetch user profile
          const userResponse = await api.auth.me();
          setUser(userResponse.data);
        } catch (err) {
          console.error('Auth init error:', err);
          setUser(null);
        }
      } else {
        setUser(null);
        api.setAccessToken(null);
      }
      setIsLoading(false);
    };

    initAuth();
  }, [isAuthenticated, account, instance]);

  const login = async () => {
    try {
      await instance.loginPopup(loginRequest);
    } catch (err) {
      console.error('Login error:', err);
    }
  };

  const logout = async () => {
    try {
      await instance.logoutPopup();
      setUser(null);
      api.setAccessToken(null);
    } catch (err) {
      console.error('Logout error:', err);
    }
  };

  return (
    <AuthContext.Provider value={{ user, isLoading, isAuthenticated, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
```

---

### Phase 3: Infrastructure (Week 4)

**Goal**: Single Bicep deployment for all resources

#### Task 3.1: Simplified Bicep Template

The existing `main-modernized.bicep` should be updated to use:

- Resource Group: `vigor-rg`
- Region: West US 2
- Function App: Flex Consumption
- No environment suffix naming
- gpt-5-mini as AI model

Key environment variables for Function App:

```
OPENAI_API_KEY=<from-key-vault>
OPENAI_MODEL=gpt-5-mini
COSMOS_DB_ENDPOINT=https://vigor-cosmos.documents.azure.com:443/
COSMOS_DB_DATABASE=vigor-db
AZURE_CLIENT_ID=<app-registration-client-id>
```

#### Task 3.2: Deployment Script

```bash
#!/bin/bash
# infrastructure/bicep/deploy.sh

set -e

RESOURCE_GROUP="vigor-rg"
LOCATION="westus2"

echo "🚀 Deploying Vigor Infrastructure..."

# Create resource group if it doesn't exist
az group create --name $RESOURCE_GROUP --location $LOCATION

# Get secrets from environment or prompt
if [ -z "$OPENAI_API_KEY" ]; then
    read -sp "Enter OpenAI API Key: " OPENAI_API_KEY
    echo
fi

if [ -z "$AZURE_AD_CLIENT_ID" ]; then
    read -p "Enter Azure AD Client ID: " AZURE_AD_CLIENT_ID
fi

# Deploy Bicep template
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file main-modernized.bicep \
    --parameters \
        openaiApiKey=$OPENAI_API_KEY \
        azureAdClientId=$AZURE_AD_CLIENT_ID

echo "✅ Infrastructure deployed successfully!"

# Show outputs
az deployment group show \
    --resource-group $RESOURCE_GROUP \
    --name main-modernized \
    --query properties.outputs

echo ""
echo "📝 Next steps:"
echo "1. Deploy Functions: cd functions-modernized && func azure functionapp publish vigor-func"
echo "2. Deploy Frontend: az staticwebapp deploy --name vigor-web --source frontend/dist"
```

---

### Phase 4: Testing & Quality (Week 5)

**Goal**: 80% test coverage, all critical paths tested

#### Test Coverage Targets

| Component           | Current | Target         |
| ------------------- | ------- | -------------- |
| Backend Functions   | ~45%    | 80%            |
| Frontend Components | ~8%     | 80%            |
| E2E Tests           | Minimal | Critical paths |

---

### Phase 5: Deployment & Go-Live (Week 6)

**Goal**: Production deployment with monitoring

#### Environment Variables

**Function App (vigor-func)**:

```
COSMOS_DB_ENDPOINT=https://vigor-cosmos.documents.azure.com:443/
COSMOS_DB_KEY=@Microsoft.KeyVault(...)
OPENAI_API_KEY=@Microsoft.KeyVault(...)
OPENAI_MODEL=gpt-5-mini
AZURE_CLIENT_ID=<your-app-registration-client-id>
APPLICATIONINSIGHTS_CONNECTION_STRING=<from-deployment>
```

**Static Web App (frontend/.env.production)**:

```
VITE_API_URL=https://vigor-func.azurewebsites.net/api
VITE_AZURE_CLIENT_ID=<your-app-registration-client-id>
VITE_REDIRECT_URI=https://vigor-web.azurestaticapps.net
```

---

## Part 4: Migration Checklist

### Pre-Migration

- [x] Archive redundant files to `.archive/`
- [ ] Create Azure AD App Registration
- [ ] Set up `vigor-rg` resource group in West US 2
- [ ] Configure GitHub secrets
- [ ] Back up any existing data

### Phase 0: Cleanup

- [x] Move `/functions` to `.archive/functions-abandoned`
- [x] Move `*-temp.tsx` files to `.archive/frontend-temp-components`
- [x] Archive old bicep files to `.archive/bicep-old`
- [ ] Fix hardcoded URLs in frontend
- [ ] Update auth configuration to use default tenant

### Phase 1: Backend

- [ ] Implement all function endpoints
- [ ] Replace Gemini with OpenAI gpt-5-mini
- [ ] Set up Cosmos DB containers
- [ ] Test locally with Azure Functions Core Tools

### Phase 2: Frontend

- [ ] Create unified API service
- [ ] Update all pages to use API service
- [ ] Simplify auth context (remove VedUser complexity)
- [ ] Test with local backend

### Phase 3: Infrastructure

- [ ] Update Bicep template for single environment
- [ ] Deploy to vigor-rg
- [ ] Configure Key Vault secrets
- [ ] Set up CORS on Function App

### Phase 4: Testing

- [ ] Backend tests passing (80%+)
- [ ] Frontend tests passing (80%+)
- [ ] E2E smoke tests passing

### Phase 5: Go-Live

- [ ] Deploy Functions to Azure
- [ ] Deploy Frontend to Static Web App
- [ ] Verify auth flow works
- [ ] Monitor for errors in App Insights

---

## Part 5: Estimated Costs

| Resource                           | Tier          | Monthly Estimate |
| ---------------------------------- | ------------- | ---------------- |
| Azure Static Web App               | Free          | $0               |
| Azure Functions (Flex Consumption) | Pay-per-use   | $5-15            |
| Cosmos DB Serverless               | Pay-per-RU    | $5-20            |
| Key Vault                          | Standard      | $1               |
| Application Insights               | Free (5GB)    | $0               |
| OpenAI API (gpt-5-mini)            | Pay-per-token | $5-15            |
| **Total**                          |               | **$16-51/month** |

_Based on 100 daily active users with moderate usage_

---

## Part 6: Azure AD App Registration Setup

### Step-by-Step Guide

1. **Go to Azure Portal** → Microsoft Entra ID → App registrations → New registration

2. **Register Application**:
   - Name: `Vigor`
   - Supported account types: `Accounts in any organizational directory and personal Microsoft accounts`
   - Redirect URI: `Single-page application (SPA)` → `http://localhost:5173`

3. **Configure Authentication**:
   - Add additional redirect URIs:
     - `https://vigor-web.azurestaticapps.net`
     - `https://vigor-web.azurestaticapps.net/auth/callback`
   - Enable `Access tokens` and `ID tokens`
   - Allow public client flows: `Yes`

4. **Note the values**:
   - Application (client) ID → Use as `AZURE_CLIENT_ID` / `VITE_AZURE_CLIENT_ID`
   - Use `common` as tenant for multi-tenant auth

---

## Conclusion

This plan transforms Vigor from a fragmented prototype into a **production-ready, cost-efficient application**:

- **Single backend**: Azure Functions (Flex Consumption)
- **Single database**: Cosmos DB (Serverless)
- **Single AI provider**: OpenAI gpt-5-mini
- **Simple auth**: Microsoft Entra ID (default tenant)
- **Cost target**: $16-51/month

The 6-week timeline is structured for efficient execution with clear deliverables at each phase.

---

_Document Version 2.0 - January 19, 2026_  
_Updated with user requirements: gpt-5-mini, Entra ID default tenant, Flex Consumption in West US 2, single environment deployment_
