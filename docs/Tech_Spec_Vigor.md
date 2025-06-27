# Vigor - Technical Specification Document

**Version**: 1.0
**Date**: June 26, 2025
**Status**: Production Ready
**Document Owner**: Engineering Team
**Aligned with**: PRD-Vigor.md v1.0, User_Experience.md v1.0

---

## Executive Summary

This Technical Specification defines the implementation details for Vigor, an AI-powered fitness platform built with cost-optimized architecture. The system implements Clean/Hexagonal Architecture with a dual resource group strategy for Azure deployment, enabling pause/resume functionality to maintain ultra-low operational costs (~$100/month, pausable to ~$70/month).

**Key Architectural Decisions:**

- **Clean Architecture**: Domain-driven design with clear separation of concerns
- **Multi-Provider AI**: Resilient LLM orchestration with automatic failover
- **Cost-Optimized Infrastructure**: Dual resource group strategy for pause/resume capabilities
- **Single Environment**: Direct production deployment for cost efficiency
- **Modern Tech Stack**: FastAPI + React with TypeScript for type safety and performance

---

## 1. System Architecture Overview

### 1.1 High-Level Architecture

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   React Frontend    │───▶│   FastAPI Backend    │───▶│ LLM Orchestration   │
│   (TypeScript +     │    │   (Clean Arch)       │    │ (Multi-Provider)    │
│   Chakra UI)        │    │                      │    │                     │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
           │                          │                          │
           │                          ▼                          │
           │                ┌──────────────────────┐             │
           │                │   PostgreSQL DB      │             │
           │                │   (User Data &       │             │
           │                │   Workout Logs)      │             │
           │                └──────────────────────┘             │
           │                                                     │
           ▼                                                     ▼
┌─────────────────────┐                              ┌─────────────────────┐
│   Azure Static      │                              │   Azure Key Vault   │
│   Web App           │                              │   (API Keys &       │
│   (CDN + PWA)       │                              │   Secrets)          │
└─────────────────────┘                              └─────────────────────┘
```

### 1.2 Infrastructure Architecture

**Dual Resource Group Strategy:**

```
┌─────────────────────────────────────────────────────────────────────┐
│                        vigor-rg (Compute Resources)                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  App Service    │  │ Static Web App  │  │ Application     │     │
│  │  (Backend API)  │  │ (Frontend)      │  │ Insights        │     │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘     │
│          - AI/LLM Services # ~$55/month                            │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                              DELETE/RECREATE
                              (Pause/Resume)
                                    │
┌─────────────────────────────────────────────────────────────────────┐
│                      vigor-db-rg (Persistent Resources)             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │
│  │  PostgreSQL     │  │  Azure Key      │  │  Storage        │     │
│  │  Database       │  │  Vault          │  │  Account        │     │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘     │
└─────────────────────────────────────────────────────────────────────┘
                            (ALWAYS PERSISTENT)
```

---

## 2. Backend Architecture

### 2.1 Clean Architecture Implementation

The backend follows Clean/Hexagonal Architecture as defined in ADR-0001:

```
backend/
├── api/                    # Interface Layer (Controllers)
│   ├── routes/            # FastAPI endpoints
│   ├── schemas/           # Pydantic request/response models
│   └── services/          # Application service facades
├── application/            # Application Layer (Use Cases)
│   ├── llm/              # LLM orchestration use cases
│   └── services/         # Business logic orchestration
├── core/                  # Domain Layer (Business Logic)
│   ├── llm_orchestration/ # LLM domain logic
│   └── security.py       # Security domain logic
├── database/              # Infrastructure Layer (Data)
│   ├── models.py         # Pydantic domain models
│   ├── sql_models.py     # SQLAlchemy ORM models
│   └── repositories/     # Data access patterns
└── infrastructure/        # Infrastructure Layer (External)
    └── adapters/         # External service adapters
```

### 2.2 Technology Stack

#### Core Framework

- **FastAPI 0.104+**: Async web framework with automatic OpenAPI documentation
- **Python 3.12+**: Latest Python with performance improvements
- **Uvicorn**: ASGI server for production deployment
- **Pydantic v2**: Data validation and serialization

#### Database & ORM

- **PostgreSQL 14+**: Primary database with JSON support
- **SQLAlchemy 2.0+**: Async ORM with relationship management
- **Alembic**: Database migration management
- **asyncpg**: High-performance async PostgreSQL driver

#### Security & Authentication

- **Microsoft Entra External ID**: Enterprise-grade identity and access management
- **MSAL (Microsoft Authentication Library)**: OAuth 2.0/OpenID Connect integration
- **SlowAPI**: Rate limiting with Redis/memory backend
- **CORS middleware**: Cross-origin request handling
- **Azure Identity**: Seamless integration with Azure services

### 2.3 LLM Orchestration System

#### Architecture Components

The LLM system implements a sophisticated enterprise-grade orchestration layer:

```python
# Core orchestration facade
class LLMGatewayFacade:
    def __init__(self, config_manager, key_vault_service, db_session):
        # Cross-cutting services
        self._budget_manager = BudgetManager(db_session)
        self._cache_manager = CacheManager()
        self._circuit_breaker = CircuitBreakerManager()

        # Application-layer components
        self._request_validator = RequestValidator()
        self._routing_engine = RoutingEngine(config_manager)
        self._budget_enforcer = BudgetEnforcer(self._budget_manager)
        self._response_recorder = ResponseRecorder()
```

#### Multi-Provider Strategy

| Provider        | Primary Use Case         | Fallback Order                | Cost/1M Tokens |
| --------------- | ------------------------ | ----------------------------- | -------------- |
| OpenAI GPT-4    | Complex workout planning | Primary → Gemini → Perplexity | $20-60         |
| Google Gemini   | Conversational coaching  | Primary → OpenAI → Perplexity | $1.5-15        |
| Perplexity Pro  | Research-backed insights | Primary → OpenAI → Local      | $20            |
| Fallback System | Service continuity       | Local templates + rules       | $0             |

#### Key Features

- **Budget Management**: Real-time cost tracking and enforcement
- **Circuit Breaker**: Automatic failover when providers fail
- **Response Caching**: TTL-based caching for cost optimization
- **Request Validation**: Input sanitization and user context injection
- **Analytics**: Comprehensive usage tracking and performance metrics

### 2.4 Database Schema

#### Core Models

```python
# User and Authentication
class UserProfile:
    id: str                           # UUID primary key
    email: str                        # Unique email
    username: str                     # Unique username
    fitness_level: FitnessLevel       # BEGINNER, INTERMEDIATE, ADVANCED
    goals: List[FitnessGoal]         # Multiple fitness objectives
    equipment: Equipment              # Available equipment level
    tier: UserTier                   # FREE, PREMIUM, ADMIN
    created_at: datetime
    updated_at: datetime

# Workout System
class WorkoutPlan:
    id: str                          # UUID
    user_id: str                     # FK to UserProfile
    name: str                        # AI-generated name
    description: str                 # Workout overview
    exercises: List[Exercise]        # Structured exercise data
    duration_minutes: int            # Planned duration
    difficulty: str                  # Calculated difficulty
    equipment_needed: List[str]      # Required equipment
    ai_provider_used: str           # OpenAI, Gemini, etc.
    created_at: datetime

class WorkoutLog:
    id: str                          # UUID
    user_id: str                     # FK to UserProfile
    workout_plan_id: str            # FK to WorkoutPlan
    exercises_completed: List[ExerciseLog]
    duration_minutes: int            # Actual duration
    intensity: int                   # 1-10 user rating
    notes: str                       # User notes
    completed_at: datetime

# AI System
class AICoachMessage:
    id: str                          # UUID
    user_id: str                     # FK to UserProfile
    role: str                        # 'user' or 'assistant'
    content: str                     # Message content
    provider_used: str              # Which AI provider
    tokens_used: int                # Cost tracking
    response_time_ms: int           # Performance tracking
    created_at: datetime

# Budget and Usage Tracking
class BudgetSettings:
    id: str                          # UUID
    user_id: str                     # FK to UserProfile (or global)
    monthly_limit: Decimal           # Budget limit in USD
    current_usage: Decimal           # Current month spending
    alert_threshold: float           # Alert at % of budget
    auto_disable: bool               # Auto-disable when exceeded
    created_at: datetime
    updated_at: datetime
```

#### Key Relationships

```sql
-- Foreign Keys and Indexes
ALTER TABLE workout_plans ADD CONSTRAINT fk_workout_plans_user
    FOREIGN KEY (user_id) REFERENCES user_profiles(id);

ALTER TABLE workout_logs ADD CONSTRAINT fk_workout_logs_user
    FOREIGN KEY (user_id) REFERENCES user_profiles(id);

ALTER TABLE ai_coach_messages ADD CONSTRAINT fk_ai_messages_user
    FOREIGN KEY (user_id) REFERENCES user_profiles(id);

-- Performance Indexes
CREATE INDEX idx_workout_logs_user_date ON workout_logs(user_id, completed_at);
CREATE INDEX idx_ai_messages_user_date ON ai_coach_messages(user_id, created_at);
CREATE INDEX idx_workout_plans_user ON workout_plans(user_id);
```

### 2.5 API Layer

#### Authentication & Security

```python
# Microsoft Entra External ID Authentication
@router.post("/auth/login")
@limiter.limit("10/minute")
async def login(credentials: LoginRequest) -> TokenResponse:
    """Authenticate user via Microsoft Entra External ID"""

@router.get("/auth/oauth/{provider}")
async def oauth_login(provider: str) -> RedirectResponse:
    """Initiate OAuth flow via Entra External ID (google/apple/microsoft)"""

@router.post("/auth/register")
@limiter.limit("5/minute")
async def register(user_data: RegisterRequest) -> UserResponse:
    """Create new user account with Entra External ID integration"""

# Protected endpoints with OAuth token validation
@router.get("/users/me")
async def get_current_user(
    current_user: UserResponse = Depends(get_current_user_entra)
) -> UserResponse:
    """Get current user profile"""
```

#### Enhanced AI Cost Management Endpoints

```python
# Real-time Cost Monitoring
@router.get("/admin/ai/costs/real-time")
async def get_real_time_costs(
    admin_user: UserResponse = Depends(require_admin)
) -> CostMonitoringResponse:
    """Get real-time AI cost metrics and budget utilization"""

@router.post("/ai/budget/validate")
@limiter.limit("100/minute")
async def validate_budget_before_operation(
    operation: BudgetValidationRequest,
    current_user: UserResponse = Depends(get_current_user_entra)
) -> BudgetValidationResponse:
    """Validate budget before expensive AI operations"""

# Automated Cost Management
@router.post("/admin/ai/cost-management/configure")
async def configure_cost_management(
    config: CostManagementConfig,
    admin_user: UserResponse = Depends(require_admin)
) -> ConfigurationResponse:
    """Configure automated cost management rules and thresholds"""

@router.post("/ai/model/switch")
async def trigger_dynamic_model_switch(
    switch_request: ModelSwitchRequest,
    admin_user: UserResponse = Depends(require_admin)
) -> ModelSwitchResponse:
    """Execute dynamic model switching for cost optimization"""

# Cost Analytics and Forecasting
@router.get("/admin/ai/costs/analytics")
async def get_cost_analytics(
    time_range: str = "30d",
    admin_user: UserResponse = Depends(require_admin)
) -> CostAnalyticsResponse:
    """Get detailed cost analytics and forecasting data"""

@router.get("/admin/ai/costs/per-user")
async def get_per_user_costs(
    admin_user: UserResponse = Depends(require_admin)
) -> PerUserCostResponse:
    """Get per-user AI cost breakdown and usage patterns"""
```

#### Core Endpoints

```python
# AI Workflow Endpoints
@router.post("/ai/workout-plan")
@limiter.limit("30/minute")
async def generate_workout_plan(
    request: WorkoutPlanRequest,
    current_user: UserResponse = Depends(get_current_user)
) -> WorkoutPlanResponse:
    """Generate personalized workout using LLM orchestration"""

@router.post("/ai/chat")
@limiter.limit("60/minute")
async def chat_with_coach(
    message: ChatRequest,
    current_user: UserResponse = Depends(get_current_user)
) -> ChatResponse:
    """Conversational AI coaching interface"""

# Workout Management
@router.post("/workouts/logs")
async def log_workout(
    workout_log: WorkoutLogCreate,
    current_user: UserResponse = Depends(get_current_user)
) -> WorkoutLogResponse:
    """Log completed workout with analytics"""

@router.get("/workouts/logs")
async def get_workout_history(
    current_user: UserResponse = Depends(get_current_user),
    limit: int = 50
) -> List[WorkoutLogResponse]:
    """Get user's workout history with pagination"""
```

#### Admin & Monitoring

```python
# LLM Administration
@router.get("/llm/status")
async def get_llm_status() -> SystemStatusResponse:
    """Get LLM provider health and performance metrics"""

@router.post("/llm/admin/models")
async def configure_model(
    config: ModelConfiguration,
    admin_user: UserResponse = Depends(require_admin)
) -> ConfigurationResponse:
    """Configure LLM provider settings (admin only)"""

# System Health
@router.get("/health")
@limiter.limit("100/minute")
async def health_check() -> HealthResponse:
    """System health check with dependency validation"""
```

---

## 3. Frontend Architecture

### 3.1 Technology Stack

#### Core Framework

- **React 19**: Latest React with server components and improved performance
- **TypeScript 5**: Strong typing for better developer experience
- **Vite**: Fast build tool with HMR and optimized bundling
- **Chakra UI v3**: Accessible component library with consistent design

#### State Management

- **Zustand**: Lightweight state management for global state
- **React Context**: Authentication and user session management
- **TanStack Query**: Server state management and caching
- **React Hook Form**: Form state and validation

#### Routing & Navigation

- **React Router v6**: Client-side routing with nested routes
- **Protected Routes**: Authentication-aware route protection
- **Layout Components**: Consistent navigation and layout structure

### 3.2 Application Structure

```
frontend/src/
├── components/              # Reusable UI components
│   ├── Layout.tsx          # Main layout with sidebar
│   ├── ProtectedRoute.tsx  # Route protection wrapper
│   ├── LLMStatus.tsx       # AI system status display
│   └── QuickReplies.tsx    # Support interface components
├── pages/                   # Route-level components
│   ├── DashboardPage.tsx   # Main user dashboard
│   ├── WorkoutPage.tsx     # Workout generation and tracking
│   ├── CoachPage.tsx       # AI coach chat interface
│   ├── AdminPage.tsx       # Admin management console
│   └── LLMOrchestrationPage.tsx # LLM system management
├── contexts/                # React context providers
│   ├── AuthContext.tsx     # Authentication state
│   └── useAuth.ts          # Authentication hook
├── services/                # API communication
│   ├── authService.ts      # Authentication API calls
│   ├── workoutService.ts   # Workout-related API calls
│   ├── adminService.ts     # Admin management API calls
│   └── supportService.ts   # Support functionality
├── stores/                  # Zustand state stores
│   └── chatStore.ts        # Chat state management
├── types/                   # TypeScript type definitions
│   ├── auth.ts             # Authentication types
│   ├── workout.ts          # Workout-related types
│   └── admin.ts            # Admin interface types
└── utils/                   # Utility functions
    └── streak.ts           # Streak calculation utilities
```

### 3.3 Key Components Implementation

#### Authentication System

```typescript
// AuthContext.tsx - Global authentication state
interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, username: string, password: string) => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Token validation and auto-refresh logic
  useEffect(() => {
    const checkAuthStatus = async () => {
      const token = localStorage.getItem('accessToken');
      if (token) {
        try {
          const userData = await authService.getCurrentUser();
          setUser(userData);
        } catch (error) {
          localStorage.removeItem('accessToken');
          localStorage.removeItem('refreshToken');
        }
      }
      setIsLoading(false);
    };
    checkAuthStatus();
  }, []);
```

#### Layout and Navigation

```typescript
// Layout.tsx - Main application layout
export const Layout = () => {
  const { user, logout } = useAuth();
  const location = useLocation();

  const Links = [
    { name: "Dashboard", path: "/" },
    { name: "Workouts", path: "/workouts" },
    { name: "AI Coach", path: "/coach" },
    { name: "Profile", path: "/profile" },
  ];

  return (
    <Flex minH="100vh" bg="gray.50">
      {/* Responsive Sidebar */}
      <Box bg="white" w="250px" p={6} display={{ base: "none", md: "block" }}>
        <Heading size="lg" color="blue.500" mb={8}>
          Vigor
        </Heading>
        {/* Navigation Links */}
      </Box>

      {/* Main Content */}
      <Box flex="1">
        <Outlet />
      </Box>
    </Flex>
  );
};
```

#### AI Coach Interface

```typescript
// CoachPage.tsx - AI coaching interface
export const CoachPage = () => {
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputMessage, setInputMessage] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const sendMessage = async () => {
    if (!inputMessage.trim()) return;

    const userMessage: Message = {
      role: 'user',
      content: inputMessage,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setIsLoading(true);

    try {
      const response = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          message: inputMessage,
          context: { page: 'coach' }
        })
      });

      const aiResponse = await response.json();
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: aiResponse.content,
        timestamp: new Date()
      }]);
    } catch (error) {
      console.error('Error sending message:', error);
    } finally {
      setIsLoading(false);
    }
  };
```

### 3.4 Build and Deployment

#### Development Configuration

```typescript
// vite.config.ts
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api": {
        target: "http://localhost:8000",
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ""),
      },
    },
  },
  build: {
    outDir: "dist",
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ["react", "react-dom"],
          router: ["react-router-dom"],
          ui: ["@chakra-ui/react"],
          query: ["@tanstack/react-query"],
        },
      },
    },
  },
});
```

#### Progressive Web App (PWA)

- **Service Worker**: Workbox-based caching for offline functionality
- **Manifest**: Native app-like installation capabilities
- **Push Notifications**: Web Push API for user engagement
- **Offline Support**: Critical UI components work without connectivity

---

## 4. Enhanced AI Cost Management & Automation

### 4.1 Real-Time Cost Tracking Architecture

The AI Cost Management system implements comprehensive cost tracking, budget validation, and automated optimization to maintain operational costs within target limits (~$100/month).

#### Core Components:

- **Real-time token usage tracking** for all Azure OpenAI operations
- **Budget validation** before expensive LLM operations
- **Intelligent caching layer** using Python functools.lru_cache for RAG responses
- **Dynamic fallback mechanisms** for budget constraints
- **Cost-effective model switching** (GPT-4-Turbo → GPT-3.5-Turbo; Gemini Pro → Flash)
- **Request batching and query deduplication** for cost optimization
- **Graceful degradation** with user notification system
- **AI cost forecasting** and budget planning tools
- **Per-user AI usage limits** with enforcement and override capabilities
- **Azure Cost Management API integration** for automated alerts and throttling

### 4.2 Implementation Overview

```python
from functools import lru_cache
from azure.mgmt.consumption import ConsumptionManagementClient
from azure.identity import DefaultAzureCredential

class AICostManager:
    def __init__(self):
        self.credential = DefaultAzureCredential()
        self.consumption_client = ConsumptionManagementClient(
            credential=self.credential,
            subscription_id=os.getenv("AZURE_SUBSCRIPTION_ID")
        )
        self.budget_limits = {
            "monthly_total": 200.00,
            "daily_limit": 10.00,
            "per_user_free": 0.10,
            "per_user_premium": 2.00
        }

    async def validate_budget_before_operation(self, operation_type: str, estimated_tokens: int, user_id: str):
        """Validate budget before expensive operations"""
        # Implementation details in next section
        pass

    @lru_cache(maxsize=1000, typed=True)
    async def get_cached_ai_response(self, prompt_hash: str, model: str):
        """Intelligent caching layer for AI responses"""
        # Implementation details in next section
        pass
```

---

## 5. Infrastructure & DevOps

### 5.1 Azure Cloud Architecture

#### Resource Configuration

```yaml
# Resource Groups Structure
vigor-rg: # Compute resources (deletable)
  - App Service Plan (B1) # ~$13/month
  - App Service (Backend) # Included in plan
  - Static Web App (Free) # $0/month
  - Application Insights # ~$2/month
  - Log Analytics Workspace # ~$3/month
  - AI/LLM Services # ~$55/month

vigor-db-rg: # Persistent resources (permanent)
  - PostgreSQL Flexible # ~$25/month
  - Azure Key Vault # ~$3/month
  - Storage Account (LRS) # ~$2/month
```

**Total Monthly Cost**: ~$100/month
**Pause Mode Cost**: ~$70/month (delete vigor-rg, keep vigor-db-rg)

#### Bicep Infrastructure as Code

```bicep
// main.bicep - Dual resource group deployment
param databaseResourceGroup string = 'vigor-db-rg'
param useDirectDeployment bool = true

// Compute resources in main RG
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'vigor-app-plan'
  location: location
  sku: { name: 'B1' }  // Cost-optimized tier
  kind: 'linux'
  properties: { reserved: true }
}

// Database resources in separate RG for persistence
module db './db.bicep' = {
  name: 'dbModule'
  scope: resourceGroup(databaseResourceGroup)
  params: {
    postgresServerName: 'vigor-db-server'
    postgresAdminUsername: postgresAdminUsername
    postgresAdminPassword: postgresAdminPassword
  }
}
```

### 5.2 Application Configuration

#### Environment Variables

```bash
# Microsoft Entra ID Configuration
AZURE_TENANT_ID=VED
AZURE_DOMAIN_ID=VedID.onmicrosoft.com
AZURE_RESOURCE_GROUP_ID=ved-id-rg
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}

# Database Configuration
DATABASE_URL=${DATABASE_URL}
POSTGRES_DB=vigor_prod
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# AI Cost Management
AZURE_MONTHLY_BUDGET=100
AI_COST_THRESHOLD=85
LLM_PROVIDER=fallback
OPENAI_API_KEY=${OPENAI_API_KEY}
GOOGLE_AI_API_KEY=${GOOGLE_AI_API_KEY}
PERPLEXITY_API_KEY=${PERPLEXITY_API_KEY}

# Application Settings
ENVIRONMENT=production
LOG_LEVEL=INFO
JWT_SECRET_KEY=${JWT_SECRET_KEY}
```

#### Application Secrets

All sensitive configuration values are stored in Azure Key Vault:

- **AZURE_CLIENT_SECRET**: Entra ID application secret
- **DATABASE_URL**: PostgreSQL connection string
- **JWT_SECRET_KEY**: Session token signing key
- **OPENAI_API_KEY**: OpenAI API access key
- **GOOGLE_AI_API_KEY**: Google AI API access key
- **PERPLEXITY_API_KEY**: Perplexity API access key

### 5.3 CI/CD Pipeline

#### GitHub Actions Workflow

```yaml
# .github/workflows/simple-deploy.yml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Backend deployment
      - name: Deploy Backend to App Service
        uses: azure/webapps-deploy@v2
        with:
          app-name: vigor-backend
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
          package: ./backend

      # Frontend deployment
      - name: Deploy Frontend to Static Web App
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "./frontend"
          output_location: "dist"
```

#### Deployment Strategy

- **Single Environment**: Direct production deployment for cost efficiency
- **Single Slot**: No staging slots to reduce infrastructure costs
- **Health Checks**: Automated validation post-deployment
- **Rollback**: Git-based rollback strategy

### 5.4 Monitoring & Observability

#### Application Insights Configuration

```python
# OpenTelemetry tracing setup
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor

# Instrument FastAPI application
FastAPIInstrumentor.instrument_app(app)
SQLAlchemyInstrumentor().instrument()

# Custom tracing for LLM operations
@trace.get_tracer(__name__)
async def trace_llm_request(provider: str, request_data: dict):
    with trace.get_current_span() as span:
        span.set_attributes({
            "llm.provider": provider,
            "llm.tokens": request_data.get("max_tokens", 0),
            "llm.model": request_data.get("model", "unknown")
        })
```

#### Health Check Implementation

```python
@router.get("/health")
@limiter.limit("100/minute")
async def health_check():
    """Comprehensive health check with dependency validation"""
    health_status = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "checks": {}
    }

    # Database health
    try:
        await db_health_check()
        health_status["checks"]["database"] = "healthy"
    except Exception as e:
        health_status["checks"]["database"] = f"unhealthy: {str(e)}"
        health_status["status"] = "degraded"

    # LLM providers health
    try:
        llm_status = await check_llm_providers()
        health_status["checks"]["llm_providers"] = llm_status
    except Exception as e:
        health_status["checks"]["llm_providers"] = f"unhealthy: {str(e)}"

    return health_status
```

---

## 6. Data Models & API Contracts

### 6.1 API Request/Response Schemas

#### Authentication

```python
# Pydantic schemas for type safety
class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)

class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse

class UserResponse(BaseModel):
    id: str
    email: EmailStr
    username: str
    fitness_level: Optional[FitnessLevel]
    goals: List[FitnessGoal]
    tier: UserTier
    created_at: datetime
```

#### Workout System

```python
class WorkoutPlanRequest(BaseModel):
    goals: Optional[List[str]] = Field(default_factory=list)
    equipment: Optional[str] = "bodyweight"
    duration_minutes: int = Field(ge=15, le=120, default=45)
    focus_areas: Optional[List[str]] = Field(default_factory=list)
    intensity: Optional[str] = "moderate"

class Exercise(BaseModel):
    name: str
    sets: int = Field(ge=1, le=10)
    reps: str  # "8-12" or "10"
    rest_seconds: int = Field(ge=30, le=300)
    instructions: str
    modifications: Optional[str]
    muscle_groups: List[str]
    equipment_needed: List[str]

class WorkoutPlanResponse(BaseModel):
    id: str
    name: str
    description: str
    exercises: List[Exercise]
    duration_minutes: int
    difficulty: str
    equipment_needed: List[str]
    ai_provider_used: str
    estimated_calories: Optional[int]
    created_at: datetime
```

#### AI Coach Interface

```python
class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=1000)
    context: Optional[Dict[str, Any]] = Field(default_factory=dict)

class ChatResponse(BaseModel):
    content: str
    provider_used: str
    tokens_used: int
    response_time_ms: int
    confidence_score: Optional[float]
    created_at: datetime
```

### 6.2 Error Response Standards

```python
class ErrorResponse(BaseModel):
    error: ErrorDetail

class ErrorDetail(BaseModel):
    code: str
    message: str
    details: Optional[Dict[str, Any]]
    timestamp: datetime
    request_id: str

# Example error responses
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "details": {
      "field": "duration_minutes",
      "constraint": "Must be between 15 and 120 minutes"
    },
    "timestamp": "2025-06-26T10:30:00Z",
    "request_id": "req_abc123"
  }
}

{
  "error": {
    "code": "AI_SERVICE_UNAVAILABLE",
    "message": "AI service temporarily unavailable",
    "details": {
      "fallback_used": true,
      "retry_after": 30,
      "degraded_mode": "basic_workout_templates"
    },
    "timestamp": "2025-06-26T10:30:00Z",
    "request_id": "req_def456"
  }
}
```

---

## 7. Security Implementation

### 7.1 Authentication & Authorization

#### Microsoft Entra External ID Integration

```python
from msal import ConfidentialClientApplication
from azure.identity import DefaultAzureCredential

class EntraAuthService:
    def __init__(self, tenant_id: str, client_id: str, client_secret: str):
        self.tenant_id = tenant_id
        self.client_id = client_id
        self.app = ConfidentialClientApplication(
            client_id=client_id,
            client_credential=client_secret,
            authority=f"https://login.microsoftonline.com/{tenant_id}"
        )
        self.credential = DefaultAzureCredential()

    async def initiate_oauth_flow(self, provider: str) -> str:
        """Initiate OAuth flow for social login providers"""
        auth_url = self.app.get_authorization_request_url(
            scopes=["openid", "profile", "email"],
            redirect_uri=f"/auth/callback/{provider}"
        )
        return auth_url

    async def validate_token(self, token: str) -> Dict[str, Any]:
        """Validate OAuth token from Entra External ID"""
        try:
            # Validate token with Microsoft Graph API
            headers = {"Authorization": f"Bearer {token}"}
            # Token validation logic with Entra External ID
            return await self._validate_with_entra(token)
        except Exception as e:
            raise HTTPException(status_code=401, detail="Invalid token")

    async def get_user_profile(self, token: str) -> Dict[str, Any]:
        """Get user profile from Entra External ID"""
        headers = {"Authorization": f"Bearer {token}"}
        # Profile retrieval logic
        return profile_data

# Dependency for protected routes
async def get_current_user_entra(
    authorization: str = Header(..., description="Bearer token from Entra External ID")
) -> UserResponse:
    """Extract and validate user from Entra External ID token"""
    try:
        token = authorization.replace("Bearer ", "")
        auth_service = EntraAuthService()
        user_data = await auth_service.validate_token(token)
        return UserResponse(**user_data)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid authentication")
```
