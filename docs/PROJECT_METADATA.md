# PROJECT_METADATA.md

## 1. Project Overview

### 1.1 Purpose

Vigor is an AI-powered fitness and wellness companion designed to provide personalized, intelligent coaching and support for users' health journeys. The platform combines artificial intelligence, computer vision, and behavioral science to deliver a proactive, motivating, and comprehensive fitness experience.

**MVP Focus**: Secure user onboarding, personalized workout plan generation, workout logging with progress tracking, and AI-powered motivational coaching.

### 1.2 Stakeholders

- **End Users**: Fitness enthusiasts of all levels seeking personalized workout plans and AI-powered coaching
- **Administrators**: System administrators managing user tiers, LLM providers, and platform operations
- **Developers**: Full-stack development team maintaining and extending the platform
- **Business**: Product team tracking user engagement, satisfaction, and retention metrics

### 1.3 High-Level Goals & Success Metrics

#### User Satisfaction & Engagement

- **User Satisfaction**: Achieve 90% user satisfaction with workout plan personalization
- **User Retention**: Maintain 80% user retention through the first month
- **Weekly Engagement**: 70% of users log at least 3 workouts per week
- **AI Interaction**: 60% of users interact with the AI coach weekly
- **Session Duration**: Average session duration of 5+ minutes
- **User Rating**: 4.5+ star average rating with 75% recommending to friends

#### Technical Performance

- **System Uptime**: 99.9% uptime requirement
- **API Performance**: Response times under 200ms
- **AI Response Speed**: Successful workout plan generation in under 3 seconds
- **Security Compliance**: 100% GDPR compliance and data security
- **User Satisfaction**: 80% report plan personalization as "good" or better

#### Business Metrics

- **Growth**: 30% month-over-month user growth target
- **Retention**: 40% user retention after 30 days minimum
- **Security Confidence**: Less than 1% of users report security concerns
- **Plan Effectiveness**: Users report plan personalization as effective

### 1.4 Development Phases

- **Phase 1 (MVP)**: Secure onboarding, AI workout planning, logging, motivational coaching
- **Phase 2**: Computer vision form analysis, wearables integration, adaptive recovery
- **Phase 3**: Habit building, voice guidance, mood tracking, community features

## 2. System Architecture

### 2.1 Overview & Diagram

```mermaid
graph TB
    subgraph "Frontend Layer"
        UI[React/TypeScript SPA]
        Auth[Authentication Context]
        Pages[Page Components]
    end

    subgraph "Backend API Layer"
        API[FastAPI Application]
        Routes[API Routes]
        Services[Business Services]
    end

    subgraph "Core Services"
        LLM[LLM Orchestration]
        Admin[Admin Management]
        Security[Security & Auth]
    end

    subgraph "Data Layer"
        DB[(SQLite Database)]
        Models[SQLAlchemy Models]
    end

    subgraph "External Services"
        OpenAI[OpenAI API]
        Providers[Other LLM Providers]
    end

    UI --> API
    API --> Services
    Services --> Core Services
    Core Services --> Models
    Models --> DB
    LLM --> Providers
```

### 2.2 Technology Stack

**Frontend:**

- React 18 with TypeScript
- Vite (build tool)
- Chakra UI (component library and styling)
- Jest + React Testing Library (testing)

**Backend:**

- Python 3.12+ (FastAPI framework)
- SQLAlchemy 2.0+ (async ORM)
- Alembic (database migrations)
- SQLite (development) / PostgreSQL (production)
- Pydantic v2 (data validation and serialization)
- AsyncIO for high-performance async operations

**DevOps & Infrastructure:**

- Docker (containerization)
- GitHub Actions (CI/CD pipeline)
- Terraform (Azure infrastructure as code)
- Azure Container Registry & App Service
- Azure Key Vault (secrets management)
- Pre-commit hooks (black, isort, bandit security scanning)

**AI/ML & LLM Integration:**

- Multi-provider LLM orchestration (OpenAI, Google Gemini, Perplexity)
- Enterprise-grade LLM gateway with intelligent routing
- Cost optimization and budget management
- Circuit breaker pattern for resilience
- Response caching and usage analytics

### 2.3 Core Components & Interactions

- **Frontend SPA**: User interface for workout management, AI coaching, and account management
- **API Gateway**: FastAPI-based REST API handling all client requests
- **LLM Orchestration**: Smart routing and fallback system for AI provider management
- **Admin System**: Comprehensive admin panel for user/system management
- **Authentication**: JWT-based authentication with role-based access control

### 2.4 Data Model Overview

**Core User System:**

- **Users (UserProfileDB)**: Complete user profiles with fitness preferences, equipment, goals, and injury history
- **User Tiers**: Three-tier system (FREE/PREMIUM/UNLIMITED) with usage limits and budget controls
- **Usage Tracking**: Real-time monitoring of API calls, costs, and tier limit enforcement

**Fitness & Workout Management:**

- **Workout Plans (WorkoutPlanDB)**: AI-generated personalized workout routines with exercise details
- **Workout Logs (WorkoutLogDB)**: Comprehensive session tracking with sets, reps, weight, and RPE ratings
- **Progress Metrics (ProgressMetricsDB)**: Body measurements, weight, and fitness milestone tracking

**AI & LLM Integration:**

- **AI Coach Messages (AICoachMessageDB)**: Conversation history and coaching interactions
- **LLM Usage Analytics**: Provider selection, costs, response times, and performance metrics
- **Admin Configuration**: Dynamic LLM provider management and system settings

**Implemented Database Schema:**

```sql
-- User tier limits (actual production values)
user_tier_limits:
  - free: 10 daily, 50 weekly, 200 monthly, $5 budget
  - premium: 50 daily, 300 weekly, 1000 monthly, $25 budget
  - unlimited: 1000 daily, 5000 weekly, 20000 monthly, $100 budget

-- User profiles with tier management
user_profiles:
  - user_tier (free/premium/unlimited)
  - monthly_budget, current_month_usage
  - fitness_level, goals[], equipment, injuries[]
  - tier_updated_at for billing cycles

-- Usage tracking per user
user_usage_limits:
  - daily/weekly/monthly request counters
  - automatic reset logic by date
  - real-time limit enforcement
```

## 2.5 CI/CD Pipeline Architecture

### 2.5.1 Enterprise-Grade Pipeline Overview

The Vigor application utilizes a comprehensive GitHub Actions CI/CD pipeline designed for Azure cloud deployment with enterprise-level security, testing, and deployment practices. The pipeline features progressive deployment from development through staging to production with zero-downtime blue-green deployments.

```mermaid
graph TB
    subgraph "Development Workflow"
        PR[Pull Request] --> Security[Security Scanning]
        Security --> Tests[Automated Testing]
        Tests --> Preview[PR Preview Environment]
    end

    subgraph "Deployment Pipeline"
        Merge[Merge to Main] --> Build[Docker Build & Push]
        Build --> Infrastructure[Terraform Validation]
        Infrastructure --> Deploy[Multi-Environment Deploy]
        Deploy --> Production[Blue-Green Production]
    end

    subgraph "Environments"
        Dev[Development<br/>Auto-deploy from develop]
        Staging[Staging<br/>Auto-deploy from main]
        Prod[Production<br/>Blue-Green deployment]
    end

    subgraph "Security & Quality"
        Trivy[Trivy Container Scanning]
        SARIF[SARIF Upload to GitHub]
        Coverage[Test Coverage Reports]
        Lint[Code Quality & Linting]
    end
```

### 2.5.2 Pipeline Jobs Architecture

**Security-First Pipeline (12 Comprehensive Jobs):**

1. **Security Scanning**

   - Trivy vulnerability scanning for containers and dependencies
   - Bandit security analysis for Python code
   - SARIF results uploaded to GitHub Security tab
   - Critical vulnerabilities block deployment

2. **Code Quality & Testing**

   - Backend: Python linting (black, isort, bandit), pytest with coverage
   - Frontend: ESLint, TypeScript checking, Jest unit tests
   - Infrastructure: Terraform format validation and security scanning
   - Comprehensive test coverage reporting with codecov integration

3. **Infrastructure Validation**

   - Terraform format checking and validation
   - Infrastructure security scanning with checkov
   - Environment-specific configuration validation
   - Cost estimation and optimization recommendations

4. **Container Build & Registry**

   - Multi-stage Docker builds for backend and frontend
   - Azure Container Registry integration with automated tagging
   - Container image vulnerability scanning before deployment
   - Image size optimization and layer caching

5. **Multi-Environment Deployment**

   - Development: Auto-deploy from `develop` branch
   - Staging: Auto-deploy from `main` branch with integration tests
   - Production: Blue-green deployment with manual approval and health checks
   - PR Previews: Temporary environments for feature branches

6. **Health Checks & Monitoring**
   - Comprehensive health check endpoints validation
   - Database connectivity and migration verification
   - LLM provider connectivity testing
   - Performance benchmarking and alerting

### 2.5.3 Branch Strategy & Environment Mapping

**Branch-Based Deployment Strategy:**

```yaml
Environment Mapping: develop branch → Development Environment
  - Automatic deployment on every push
  - Latest features for internal testing
  - Shared development database
  - Debug logging enabled

  main branch → Staging Environment
  - Automatic deployment after PR merge
  - Production-like environment for final testing
  - Integration testing with external services
  - Performance testing and monitoring

  tags (v*) → Production Environment
  - Blue-green deployment for zero downtime
  - Manual approval gate required
  - Full backup before deployment
  - Automated rollback on health check failure

  feature/* → PR Preview Environments
  - Temporary environments for code review
  - Automatic cleanup after PR close/merge
  - Isolated testing environment per feature
  - Resource optimization for cost control
```

### 2.5.4 Security Implementation

**Comprehensive Security Scanning:**

- **Container Security**: Trivy scans for OS vulnerabilities, dependencies, and secrets
- **Code Security**: Bandit static analysis for Python security issues
- **Infrastructure Security**: Checkov scans for Terraform misconfigurations
- **Dependency Security**: Automated vulnerability scanning for npm and pip packages
- **Secrets Management**: Azure Key Vault integration with automatic secret rotation

**GitHub Security Integration:**

- SARIF (Static Analysis Results Interchange Format) upload to GitHub Security tab
- Automated security advisory creation for critical vulnerabilities
- Dependabot integration for automated dependency updates
- Branch protection rules enforcing security scan completion

### 2.5.5 Azure Infrastructure Integration

**Terraform Infrastructure as Code:**

```hcl
# Environment-specific configurations
environments/
├── dev.tfvars      # Development: Minimal resources, cost-optimized
├── staging.tfvars  # Staging: Production-like with reduced capacity
└── production.tfvars # Production: High availability, auto-scaling
```

**Azure Services Integration:**

- **Azure Container Registry**: Secure container image storage with role-based access
- **Azure App Service**: Managed application hosting with auto-scaling capabilities
- **Azure Key Vault**: Centralized secrets management with access policies
- **Azure PostgreSQL**: Managed database with automated backups and monitoring
- **Azure Application Insights**: Performance monitoring and alerting

### 2.5.6 Deployment Strategies

**Blue-Green Production Deployment:**

1. **Preparation Phase**

   - Health check current production environment
   - Create full database backup
   - Prepare green environment with new deployment

2. **Deployment Phase**

   - Deploy new version to green environment
   - Run comprehensive health checks
   - Perform smoke tests and integration validation

3. **Traffic Switch**

   - Gradually route traffic from blue to green (10% → 50% → 100%)
   - Monitor application metrics and error rates
   - Automatic rollback on anomaly detection

4. **Cleanup Phase**
   - Keep blue environment as rollback option (24 hours)
   - Clean up old container images and temporary resources
   - Update monitoring and alerting configurations

**PR Preview Environments:**

- Automatic creation of isolated environments for feature branches
- Temporary subdomain allocation (e.g., `pr-123.vigor-dev.azurewebsites.net`)
- Resource limits to control costs
- Automatic cleanup 7 days after PR closure

### 2.5.7 Monitoring & Observability

**Pipeline Monitoring:**

- GitHub Actions workflow metrics and failure alerts
- Deployment duration tracking and optimization
- Security scan results trending and alerting
- Cost tracking for Azure resources across environments

**Application Monitoring:**

- Azure Application Insights integration for performance metrics
- Custom dashboard for deployment success rates and health metrics
- Automated alerting for failed deployments or health check failures
- User experience monitoring post-deployment

### 2.5.8 Secrets & Configuration Management

**GitHub Secrets (Automated via `setup-github-secrets.sh`):**

```bash
# Azure Authentication
AZURE_CLIENT_ID
AZURE_CLIENT_SECRET
AZURE_SUBSCRIPTION_ID
AZURE_TENANT_ID

# Container Registry
ACR_LOGIN_SERVER
ACR_USERNAME
ACR_PASSWORD

# Application Secrets
DATABASE_URL
JWT_SECRET_KEY
OPENAI_API_KEY
GOOGLE_AI_API_KEY

# Environment-specific configurations
DEV_* / STAGING_* / PROD_* prefixed secrets
```

**Environment Configuration:**

- Environment-specific configuration via Azure App Service settings
- Terraform variable files for infrastructure differences
- Secure secret injection at runtime from Azure Key Vault
- Configuration validation during deployment pipeline

### 2.5.9 Cost Optimization

**Resource Management Strategy:**

- **Development**: Minimal Azure resources, shared services, auto-shutdown
- **Staging**: Production-like but reduced capacity, scheduled scaling
- **Production**: Full redundancy, auto-scaling, performance optimized
- **PR Previews**: Resource limits, automatic cleanup, cost alerts

**Pipeline Efficiency:**

- Parallel job execution where possible
- Docker layer caching for faster builds
- Conditional job execution based on changed files
- Resource cleanup automation to prevent cost leaks

### 2.5.10 Disaster Recovery & Business Continuity

**Backup Strategy:**

- Automated database backups before production deployments
- Container image retention policy (30 days)
- Infrastructure state backup in Azure Storage
- Configuration backup and version control

**Rollback Procedures:**

- Automated rollback triggers on health check failures
- Manual rollback capability via GitHub Actions workflow
- Database rollback using automated backup restoration
- DNS failover configuration for critical failures

**Business Continuity:**

- Multi-region deployment readiness (infrastructure prepared)
- Cross-region backup replication
- Incident response automation and alerting
- Recovery time objective (RTO): 15 minutes
- Recovery point objective (RPO): 1 hour

### 2.5.11 Pipeline Documentation & Maintenance

**Setup Documentation:**

- Comprehensive setup guide: `docs/CI_CD_SETUP_GUIDE.md`
- Automated secrets configuration script: `scripts/setup-github-secrets.sh`
- Troubleshooting guide with common issues and solutions
- Environment setup instructions for local development

**Maintenance Procedures:**

- Monthly security update cycles for base images
- Quarterly pipeline optimization reviews
- Annual disaster recovery testing
- Continuous monitoring of pipeline performance and costs

## 3. Key Features and Functionality

### 3.1 MVP Features (Phase 1)

- **Secure User Onboarding**: OAuth2/JWT authentication with comprehensive profile collection
- **Personalized Workout Planning**: LLM-generated workout plans based on goals, fitness level, equipment, and injuries
- **Comprehensive Workout Logging**: Track sets, reps, weight, RPE, duration with visual progress graphs
- **AI-Powered Coaching**: Daily motivational messages, Q&A system, workout-specific encouragement
- **User Profile Management**: Secure storage and management of fitness data and preferences
- **Admin Dashboard**: System management interface for user/tier/provider management

### 3.2 Phase 2 Features (Post-MVP)

- **Computer Vision Form Analysis**: Upload workout videos for AI-powered form feedback
- **Adaptive Recovery Readiness**: HRV + RPE + sleep data for workout modification suggestions
- **Wearables Integration**: Apple Health, Garmin, Google Fit data integration
- **Learning Hub**: Curated fitness education content personalized to user behavior

### 3.3 Phase 3 Features (Future Vision)

- **Habit Building System**: Track hydration, mobility, sleep with streak building and smart nudges
- **Voice-Guided Workouts**: AI-narrated workouts with multiple coach personality options
- **Mood & Energy Tracking**: Check-ins that influence coaching tone and workout intensity
- **Smart Calendar Integration**: Automatic workout scheduling based on calendar availability
- **Community Features**: Group challenges, social accountability, progress sharing
- **AI Reflections**: Post-workout journaling with trend detection and insights

### 3.4 Core System Features

**User Tier Management (Fully Implemented):**

- **FREE Tier**: 10 daily, 50 weekly, 200 monthly AI requests, $5 budget
- **PREMIUM Tier**: 50 daily, 300 weekly, 1000 monthly AI requests, $25 budget
- **UNLIMITED Tier**: 1000 daily, 5000 weekly, 20000 monthly AI requests, $100 budget
- Real-time usage tracking with automatic limit enforcement
- Seamless tier upgrades and billing integration ready

**Enterprise LLM Orchestration (Production-Ready):**

- Multi-provider support: OpenAI GPT-4, Google Gemini, Perplexity
- Intelligent routing with cost optimization and fallback handling
- Circuit breaker pattern for resilience and high availability
- Response caching and budget management per user tier
- Azure Key Vault integration for secure API key management
- Comprehensive analytics and usage monitoring

**Authentication & Security:**

- JWT-based authentication with refresh token rotation
- Role-based access control (user/admin permissions)
- Input validation and sanitization across all endpoints
- GDPR-compliant data handling and encryption
- Comprehensive audit logging for admin actions

**Admin Dashboard System:**

- Real-time user management and tier assignments
- LLM provider configuration and health monitoring
- System-wide usage analytics and cost tracking
- Budget controls and usage limit management
- Security scanning and compliance reporting

## 4. Design Principles

- **Security by Design**: All user data encrypted, secure authentication, input validation
- **Scalability**: Modular architecture supporting horizontal scaling
- **Maintainability**: Clean code practices, comprehensive testing, documentation
- **Performance**: Optimized database queries, caching strategies, lazy loading
- **Reliability**: Fallback systems, error handling, graceful degradation
- **User Experience**: Responsive design, intuitive UI, fast load times

## 5. Known Constraints, Assumptions, and Design Decisions

### 5.1 Constraints

**Database & Storage:**

- Currently using SQLite for development; Azure PostgreSQL configured for production scaling
- Database connection pooling and async operations implemented for high concurrency
- File storage currently local; Azure Blob Storage integration ready for production

**LLM & AI Integration:**

- AI provider API costs managed through comprehensive tier limitations and budget controls
- Rate limiting implemented per user tier with real-time enforcement
- Response caching reduces costs while maintaining quality of service

**Infrastructure & Deployment:**

- Azure-based deployment with Container Registry and App Service
- CI/CD pipeline fully automated with security scanning and testing
- Multi-environment support (development, staging, production) configured

**Performance & Scalability:**

- Async FastAPI with SQLAlchemy 2.0 for high-performance operations
- Horizontal scaling ready with stateless JWT authentication
- Database query optimization and connection pooling implemented

### 5.2 Features Explicitly Out of Scope for MVP

- **Real-time Form Analysis**: Computer vision form feedback delayed to Phase 2
- **Wearable Device Integration**: Apple Health, Garmin integration in Phase 2
- **Social Features**: Community challenges and social accountability in Phase 3
- **Voice-Guided Workouts**: AI narrated workouts scheduled for Phase 3
- **Calendar Integration**: Smart scheduling features in Phase 3
- **Mobile App**: Initial focus on responsive web platform only
- **Nutrition Tracking**: Meal planning and nutrition features not planned
- **Live Video Coaching**: Real-time video sessions not in roadmap

### 5.2 Assumptions

- Users have stable internet connectivity for AI features
- LLM providers maintain reasonable API availability and response times
- User data volume will grow predictably with user base expansion

### 5.3 Design Decisions & Rationale

**Architecture Decisions:**

- **FastAPI over Django**: Chosen for superior async support, automatic OpenAPI documentation, and modern Python 3.12+ features with excellent performance
- **SQLAlchemy 2.0 Async**: Modern async ORM patterns for high-concurrency database operations with connection pooling
- **React + TypeScript**: Type-safe modern frontend with excellent developer experience and component reusability
- **Chakra UI over Tailwind**: Component library approach for consistent design system and faster development

**Infrastructure & Deployment:**

- **Azure over AWS**: Azure-native deployment with Container Registry, App Service, Key Vault, and PostgreSQL
- **Terraform IaC**: Infrastructure as Code for reproducible, version-controlled deployments
- **GitHub Actions CI/CD**: Comprehensive pipeline with testing, security scanning, and automated deployment

**Security & Authentication:**

- **JWT with Refresh**: Stateless authentication supporting horizontal scaling with secure token rotation
- **Azure Key Vault**: Centralized secret management for API keys and sensitive configuration
- **Role-based Access**: Granular permissions system for user/admin separation

**AI & LLM Strategy:**

- **Multi-Provider Orchestration**: Custom enterprise-grade system supporting OpenAI, Gemini, Perplexity with intelligent routing
- **Cost-First Design**: Comprehensive budget management, usage tracking, and tier-based limitations
- **Resilience Patterns**: Circuit breaker, caching, and fallback systems for high availability
- **Provider Agnostic**: Abstract interfaces allowing easy addition of new LLM providers

**Business Model Alignment:**

- **Tier-Based Architecture**: Three-tier freemium model (FREE/PREMIUM/UNLIMITED) with clear upgrade incentives
- **Usage-Based Billing**: Real-time cost tracking and budget enforcement per user tier
- **Enterprise-Ready**: Admin dashboard, comprehensive analytics, and system management capabilities

## 6. Core Modules/Services and Responsibilities

### 6.1 Backend Modules

**API Layer (`api/`):**

- `routes/auth.py`: JWT authentication, registration, login, token refresh
- `routes/ai.py`: AI chat, workout generation, coaching interactions
- `routes/workouts.py`: Workout CRUD, logging, progress tracking
- `routes/users.py`: User profile management, preferences, settings
- `routes/admin.py`: Administrative functions, user management, system controls
- `routes/tiers.py`: Tier management, usage tracking, billing integration
- `routes/llm_orchestration.py`: LLM provider management and configuration

**Service Layer (`api/services/`):**

- `auth.py`: Authentication business logic, JWT handling, user sessions
- `ai.py`: AI orchestration, prompt management, response processing
- `usage_tracking.py`: Real-time usage monitoring, tier limit enforcement
- `users.py`: User management, profile updates, preference handling

**Core System (`core/`):**

- `llm_orchestration/`: Enterprise LLM management system
  - `gateway.py`: Central LLM orchestration with intelligent routing
  - `adapters.py`: Provider-specific implementations (OpenAI, Gemini, Perplexity)
  - `budget_manager.py`: Cost tracking and budget enforcement
  - `cache_manager.py`: Response caching for performance optimization
  - `circuit_breaker.py`: Resilience patterns and failure handling
  - `routing.py`: Intelligent provider selection and fallback logic
  - `analytics.py`: Usage analytics and performance monitoring
- `admin_llm_manager.py`: Administrative LLM operations and configuration
- `security.py`: Security utilities, encryption, input validation
- `config.py`: Application configuration management and environment settings
- `llm_providers.py`: Direct provider integrations and fallback systems

**Data Layer (`database/`):**

- `models.py`: Pydantic models for request/response validation
- `sql_models.py`: SQLAlchemy ORM models with relationships
- `connection.py`: Async database connection management
- `init_db.py`: Database initialization, seeding, and migration support

**Database Migrations (`alembic/versions/`):**

- `002_add_admin_tables.py`: Admin user and permission system
- `003_add_user_tiers.py`: User tier system with usage limits and budgets
- Comprehensive migration history with rollback support

### 6.2 Frontend Modules

**Component Architecture (`src/`):**

- `components/`: Reusable UI components built with Chakra UI
  - Authentication components (LoginForm, RegisterForm)
  - Workout components (PlanGenerator, SessionLogger, ProgressCharts)
  - AI coaching interface (ChatInterface, CoachingPanel)
  - Admin dashboard components (UserManagement, SystemMetrics)
- `pages/`: Route-based page components with protected routing
  - Dashboard, WorkoutPlanner, CoachPage, AdminPage, ProfilePage
- `contexts/`: React context providers for global state management
  - AuthContext (user authentication and session management)
  - ThemeContext (dark/light mode and UI preferences)
  - AIContext (AI conversation state and provider management)
- `services/`: API client services and external integrations
  - authService.ts (authentication API calls)
  - aiService.ts (AI and LLM interactions)
  - workoutService.ts (workout management)
  - adminService.ts (admin operations)
- `types/`: TypeScript type definitions matching backend models
  - User types, workout types, AI response types
  - API request/response interfaces
- `hooks/`: Custom React hooks for common functionality
  - useAuth, useAI, useWorkouts, useAdmin

## 7. Key APIs and Data Contracts

### 7.1 Authentication APIs

- `POST /auth/login`: User authentication with JWT token generation
- `POST /auth/register`: User registration with profile creation
- `POST /auth/refresh`: JWT token refresh for session management
- `POST /auth/logout`: Secure user logout with token invalidation

### 7.2 AI/LLM APIs

- `POST /ai/chat`: AI conversation endpoint with context management
- `POST /ai/generate-workout`: Generate personalized workout plans
- `GET /ai/recommendations`: Get AI-powered fitness recommendations
- `POST /ai/workout-analysis`: Analyze workout performance and provide feedback

### 7.3 User Management APIs

- `GET /users/profile`: Retrieve complete user profile and preferences
- `PUT /users/profile`: Update user profile, goals, and fitness data
- `GET /users/tier`: Get current user tier and usage statistics
- `PUT /users/tier`: Update user tier (admin only)

### 7.4 Tier Management APIs

- `GET /tiers/current`: Get current user tier info with usage limits
- `GET /tiers/features`: List available features per tier
- `POST /tiers/upgrade`: Request tier upgrade (payment integration ready)
- `GET /tiers/usage`: Get detailed usage analytics for current user

### 7.5 Workout APIs

- `GET /workouts/`: List user workout plans and history
- `POST /workouts/`: Create new workout plan or log session
- `PUT /workouts/{id}`: Update workout plan or session details
- `DELETE /workouts/{id}`: Delete workout plan or session
- `POST /workouts/{id}/log`: Log workout session with detailed metrics
- `GET /workouts/progress`: Get progress analytics and visualization data
- `GET /workouts/plans`: Get AI-generated personalized workout recommendations

### 7.6 Admin APIs

- `GET /admin/users`: List all users with tier and usage information
- `GET /admin/system-status`: Comprehensive system health and performance metrics
- `POST /admin/llm-providers`: Configure and manage LLM provider settings
- `GET /admin/analytics`: System-wide usage analytics and cost tracking
- `PUT /admin/users/{id}/tier`: Update user tier and permissions
- `GET /admin/costs`: Detailed LLM usage costs and budget analysis
- `POST /admin/budgets`: Set system-wide and per-user budget limits

### 7.7 LLM Orchestration APIs

- `GET /llm/providers`: List available LLM providers and their status
- `POST /llm/test`: Test LLM provider connectivity and response quality
- `GET /llm/usage`: Get LLM usage statistics and performance metrics
- `PUT /llm/config`: Update LLM provider configuration and routing rules

## 8. Critical Business Logic Summary

### 8.1 User Profile & Personalization

- **Profile Data Collection**: Fitness goals, current fitness level, available equipment, injury history, exercise preferences
- **Workout Plan Generation**: LLM-powered personalized workout plans with clear explanations for exercise selections
- **Plan Adaptation**: Dynamic adjustment based on user feedback and progress tracking
- **Equipment Consideration**: Plans adapt to user's available equipment and physical limitations

### 8.2 Workout Logging & Progress Tracking

- **Comprehensive Logging**: Sets, reps, weight, Rate of Perceived Exertion (RPE), workout duration
- **Visual Progress**: Graphs, milestones, and historical workout data visualization
- **Workout History**: Complete tracking of user's fitness journey over time
- **Progress Milestones**: Automatic detection and celebration of user achievements

### 8.3 AI Coaching & Motivation

- **Daily Motivational Messages**: Personalized encouragement based on user progress and goals
- **Q&A System**: "Ask your coach" functionality answering fitness questions in plain language
- **Workout-Specific Encouragement**: Contextual motivation during exercise sessions
- **Educational Content**: Fitness concept explanations and myth-busting

### 8.4 User Tier Management

- **Tier Validation**: All feature access checked against user tier permissions
- **Usage Limits**: AI interactions limited by tier (Basic: 10/day, Premium: 100/day, Enterprise: unlimited)
- **Billing Integration**: Tier changes trigger billing system updates

### 8.5 LLM Orchestration Logic

- **Provider Selection**: Primary provider with automatic fallback to secondary providers
- **Rate Limiting**: Per-user and system-wide rate limiting for cost control
- **Context Management**: Conversation context maintained across AI interactions

### 8.6 Security Logic

- **JWT Validation**: All protected endpoints validate JWT tokens
- **Role-Based Access**: Admin endpoints require elevated permissions
- **Data Encryption**: Sensitive user data encrypted at rest and in transit
- **GDPR Compliance**: Full compliance with data protection regulations

## 9. Glossary of Terms / Domain Concepts

- **Tier**: User subscription level determining feature access and limits
- **LLM Orchestration**: System for managing multiple AI provider integrations
- **Workout Plan**: Structured exercise routine with sets, reps, and progression
- **AI Coach**: LLM-powered virtual fitness coach providing recommendations
- **RPE (Rate of Perceived Exertion)**: 1-10 scale measuring workout intensity perception
- **HRV (Heart Rate Variability)**: Biometric used for recovery readiness assessment
- **Fallback Provider**: Secondary AI provider used when primary provider fails
- **Usage Tracking**: Monitoring user activity for billing and tier enforcement
- **Form Analysis**: Computer vision-based assessment of exercise technique
- **Recovery Readiness**: Algorithm combining multiple factors to suggest rest vs. training
- **Micro-Workouts**: Short 5-10 minute exercise sessions for busy schedules
- **Smart Nudges**: Behavioral prompts designed to encourage healthy habits

## 10. Current Risks and Technical Debt

### 10.1 Technical Debt

**Database & Performance:**

- SQLite to PostgreSQL migration path documented and Azure deployment ready
- Query optimization for large datasets implemented with async patterns
- Connection pooling and database indexing strategies in place

**Testing & Quality:**

- Frontend test coverage needs expansion beyond current component tests
- Backend has comprehensive test structure with pytest framework
- API integration tests and end-to-end testing pipeline ready

**Documentation & Standards:**

- API documentation auto-generated with OpenAPI/Swagger and actively maintained
- Code formatting enforced with black, isort, and pre-commit hooks
- TypeScript strict mode enabled for type safety

### 10.2 Production Readiness & Security

**Security Implementation Status:**

- ✅ JWT authentication with refresh token rotation implemented
- ✅ Input validation and sanitization across all API endpoints
- ✅ Azure Key Vault integration for secure secret management
- ✅ HTTPS enforcement and CORS configuration for production
- ✅ SQL injection prevention with parameterized queries
- ✅ Rate limiting per user tier with real-time enforcement
- ✅ Comprehensive audit logging for admin actions
- ✅ Security scanning with Bandit and CodeQL in CI/CD pipeline

**Infrastructure & Deployment:**

- ✅ Azure infrastructure fully configured with Terraform
- ✅ CI/CD pipeline with automated testing and security scans
- ✅ Container-based deployment with health checks
- ✅ Environment-specific configuration management
- ✅ Backup and disaster recovery procedures documented

**Monitoring & Operations:**

- ✅ Comprehensive logging with structured JSON format
- ✅ Health check endpoints for system monitoring
- ✅ Usage analytics and cost tracking per user and system-wide
- ✅ Admin dashboard for real-time system management

### 10.3 Scalability & Performance

**Current Performance Optimizations:**

- ✅ Async FastAPI with SQLAlchemy 2.0 for high-concurrency operations
- ✅ Database connection pooling and query optimization
- ✅ LLM response caching to reduce API costs and improve response times
- ✅ Efficient JSON serialization with Pydantic v2
- ✅ Frontend code splitting and lazy loading with Vite

**Scaling Architecture:**

- ✅ Stateless JWT authentication for horizontal scaling
- ✅ Azure App Service with auto-scaling configuration
- ✅ Container-based deployment for easy replication
- ✅ Azure PostgreSQL with connection pooling and read replicas ready
- ✅ Azure Blob Storage for file handling at scale

**Load Testing & Monitoring:**

- Performance benchmarks documented for key API endpoints
- Real-time monitoring with Azure Application Insights integration ready
- Database performance metrics tracking with slow query logging
- LLM provider response time monitoring and automatic failover

### 10.4 Open Product Questions (from PRD)

- **AI Response Latency**: What is the maximum acceptable latency for AI responses to user questions?
- **Feedback Mechanism**: Should we implement a feedback mechanism for workout plan effectiveness?
- **Exercise Database**: What is the minimum viable set of exercises to include in the initial database?
- **Multiple Goals**: How should we handle users with multiple concurrent fitness goals?
- **Message Frequency**: What is the appropriate frequency for AI check-ins and motivational messages?

### 11. Metadata Evolution Log

### Recent Updates

- **2024-12-XX**: Initial metadata creation with comprehensive project analysis
- **2025-01-15**: Enhanced metadata with PRD specifications and detailed feature breakdown
- **2025-01-15**: Added success metrics, open questions, and out-of-scope features
- **2025-01-15**: Integrated Phase 2 and Phase 3 roadmap details from project documentation
- **2025-06-06**: **MAJOR UPDATE** - Enhanced with verified implementation details from actual codebase
- **2025-06-06**: Added actual database schema, tier limits, and LLM orchestration architecture
- **2025-06-06**: Updated technology stack with current versions and Azure infrastructure details
- **2025-06-06**: Verified and documented production-ready security and deployment configuration
- **2025-06-06**: **DOCUMENTATION CLEANUP** - Comprehensive documentation review and cleanup completed
- **2025-06-06**: Removed 8 redundant/outdated documentation files to eliminate duplication
- **2025-06-06**: Enhanced PROJECT_METADATA.md as single source of truth with verified implementation details
- **2025-06-06**: Established PROJECT_METADATA.md as living document for all project interactions and decisions
- **2025-06-06**: **CI/CD DOCUMENTATION COMPLETE** - Added comprehensive section 2.5 documenting enterprise-grade CI/CD pipeline architecture, security implementation, multi-environment deployment strategies, and Azure infrastructure integration

### Completed Documentation (Verified Against Codebase)

- ✅ Project overview and stakeholder identification
- ✅ **UPDATED** System architecture with verified technology stack
- ✅ **ENHANCED** Database schema with actual tier limits and usage tracking
- ✅ **VERIFIED** Phase-based feature breakdown with implementation status
- ✅ Success metrics and KPIs aligned with business goals
- ✅ **DETAILED** Business logic documentation with actual code references
- ✅ **COMPREHENSIVE** API endpoint specifications with current implementation
- ✅ **UPDATED** Risk assessment showing production-ready status
- ✅ Domain terminology glossary with technical accuracy
- ✅ **NEW** Complete LLM orchestration architecture documentation
- ✅ **NEW** Azure infrastructure and deployment configuration details
- ✅ **NEW** Security implementation status and compliance documentation
- ✅ **CLEANUP** Documentation consolidation removing 8 redundant files
- ✅ **PROCESS** Established PROJECT_METADATA.md as single source of truth protocol
- ✅ **NEW** Comprehensive CI/CD Pipeline Architecture (Section 2.5) - Enterprise-grade GitHub Actions pipeline with security scanning, multi-environment deployment, blue-green production strategy, and Azure infrastructure integration

### Documentation Cleanup Summary (June 6, 2025)

**Files Removed (Redundant/Outdated):**

- `CI_CD_FIXES_COMPLETE.md` - One-time completion report, information integrated into metadata
- `CI_CD_SETUP_COMPLETE.md` - Setup instructions, covered in DEPLOYMENT_GUIDE.md
- `QUICK_START.md` - Basic setup information, redundant with README.md and guides
- `NEXT_STEPS.md` - Status report, superseded by PROJECT_STATUS_REPORT.md
- `CURSOR_EXTENSIONS_SETUP.md` - Development tool setup, not core documentation
- `vigor-cursor-tasks.md` - Development tasks, likely outdated
- `vigor-prompt.md` - Development prompt, not needed in final documentation
- `NOTICE` - Temporary file

**Retained Documentation (Unique Value):**

- `PROJECT_METADATA.md` - **ENHANCED** as single source of truth
- `README.md` - User-facing project overview
- `DEPLOYMENT_GUIDE.md` - Azure deployment instructions
- `PROJECT_STATUS_REPORT.md` - Current operational status
- `ADMIN_SYSTEM_GUIDE.md` - Admin usage guide
- `LLM_ORCHESTRATION_USAGE_GUIDE.md` - LLM operational guide
- All specialized guides with unique implementation details

### Implementation Status Verified ✅

**User Tier System:**

- ✅ Database models and migrations implemented
- ✅ Usage tracking with real-time limit enforcement
- ✅ Three-tier system: FREE (10/50/200), PREMIUM (50/300/1000), UNLIMITED (1000/5000/20000)
- ✅ Budget controls: $5, $25, $100 monthly budgets per tier

**LLM Orchestration:**

- ✅ Enterprise-grade gateway with multi-provider support
- ✅ OpenAI, Google Gemini, Perplexity adapters implemented
- ✅ Circuit breaker, caching, and intelligent routing
- ✅ Azure Key Vault integration for secure API key management
- ✅ Comprehensive cost tracking and budget enforcement

**Infrastructure & Deployment:**

- ✅ Azure infrastructure with Terraform IaC
- ✅ CI/CD pipeline with security scanning
- ✅ Container-based deployment ready
- ✅ Environment configuration management

### Remaining TODOs

- [ ] Performance benchmarking results and optimization guidelines
- [ ] User journey flow documentation with actual screenshots
- [ ] Disaster recovery and backup procedures testing
- [ ] Load testing results and scaling thresholds
- [ ] Mobile app roadmap and PWA implementation details

### Living Document Protocol

**This document serves as the single source of truth for the Vigor project and will be updated with:**

- All architectural decisions and their rationale
- Implementation status changes and milestone completions
- Code reviews findings and resolutions
- Security assessments and compliance updates
- Performance metrics and optimization results
- User feedback integration and feature refinements
- Team decisions, process changes, and lessons learned
- Infrastructure changes and deployment updates

**Update Responsibility:** All team members must update this document when making significant changes to:

- System architecture or technology stack
- Database schema or data models
- API contracts or business logic
- Security implementations or compliance status
- Infrastructure configuration or deployment processes
- User experience or interface modifications

---

## Change Proposal Template

### Proposed Change:

_Describe the proposed modification_

### Rationale:

_Explain why this change is needed_

### Affected Modules/Sections:

_List impacted components_

### Impact on Metadata:

- [ ] Update Required
- [ ] No Change Needed

### Suggested Metadata Updates:

_Specific sections requiring updates_
