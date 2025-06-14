# PROJECT_METADATA.md

## 1. Project Overview

### 1.1 Purpose

Vigor is an AI-powered fitness and wellness companion designed to provide personalized, intelligent coaching and support for users' health journeys. The platform combines artificial intelligence, computer vision, and behavioral science to deliver a proactive, motivating, and comprehensive fitness experience.

**MVP Focus**: Secure user onboarding, personalized workout plan generation, workout logging with progress tracking, and AI-powered motivational coaching.

### 1.2 Infrastructure & Deployment Status (December 2024)

**✅ COMPLETED INFRASTRUCTURE MIGRATION:**

- **Migration from Terraform to Azure Bicep**: Completed December 8, 2024
- **Azure Authentication Issues**: Resolved with OIDC-based authentication
- **CI/CD Pipeline**: Updated and functioning with Bicep deployment
- **Cost Optimization**: Eliminated Terraform state storage costs (~$5/month savings)

**🚀 NEW ARCHITECTURE TRANSITION (June 2025):**

- **Moving from Containers to App Service + Functions**: Migration in progress (June 15, 2025)
- **Reason for Change**: Persistent ACR-related deployment issues and cost optimization
- **Expected Benefits**: Simplified deployment pipeline, reduced costs, better scaling options
- **Status**: Implementation in progress, CI/CD issues fixed (June 16, 2025)
  - Fixed composite actions to properly handle secrets
  - Resolved Bicep validation errors with Static Web App output references
  - Optimized security scanning to prevent pipeline blocks (fixed Trivy scan)
  - Updated Static Web App deployment with automatic token retrieval
  - Made Docker/ACR deployment conditional based on architecture choice
  - Created CI_CD_FIXES_COMPLETE.md with detailed documentation

**🔄 CURRENT DEPLOYMENT ARCHITECTURE:**

- **Infrastructure as Code**: Azure Bicep (migrated from Terraform)
- **CI/CD Platform**: GitHub Actions with OIDC authentication
- **Backend**: Transitioning from containers to direct App Service deployment
- **New Component**: Azure Functions for AI/ML workloads
- **Frontend**: Moving to Azure Static Web Apps
- **Authentication**: Service Principal with federated identity credentials
- **Deployment Strategy**: Automated deployment on main branch with manual triggers

**📋 INFRASTRUCTURE COMPONENTS (Production-Ready):**

- **Resource Group**: vigor-rg (East US)
- **App Service Plan**: Standard S1 for production workloads
- **App Service**: Linux-based backend (Python 3.11, FastAPI)
- **Static Web App**: Frontend hosting with global CDN
- **PostgreSQL**: Flexible server with configurable storage (10GB default)
- **Redis Cache**: Standard 1GB for session management
- **Key Vault**: Secure API key management with system-assigned identities
- **Container Registry**: Premium tier with zone redundancy for production
- **Application Insights**: Performance monitoring and analytics
- **Log Analytics**: Centralized logging workspace

### 1.3 Stakeholders

- **End Users**: Fitness enthusiasts of all levels seeking personalized workout plans and AI-powered coaching
- **Administrators**: System administrators managing user tiers, LLM providers, and platform operations
- **Developers**: Full-stack development team maintaining and extending the platform
- **Business**: Product team tracking user engagement, satisfaction, and retention metrics

### 1.4 High-Level Goals & Success Metrics

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

### 1.5 Development Phases

- **Phase 1 (MVP)**: Secure onboarding, AI workout planning, logging, motivational coaching ✅
- **Phase 2**: Computer vision form analysis, wearables integration, adaptive recovery
- **Phase 3**: Habit building, voice guidance, mood tracking, community features

### 1.6 December 2024 Infrastructure Cost-Optimization Decision

Beginning December 12, 2024 the Vigor team adopted the following changes to further simplify operations and reduce Azure spend:

1. **Single Resource Group** – All Azure assets (App Service, Static Web App, PostgreSQL, Redis, Key Vault, Container Registry, etc.) are now deployed into a single, convention-based resource group `vigor-rg` (East US). This eliminates the overhead of multiple RGs (~$0.20/month per RG for diagnostic logs & policies) and makes quota allocation simpler.
2. **Bicep-Only IaC** – Terraform modules and remote state were fully removed. Azure Bicep is now the sole IaC language, leveraging native deployment features and OIDC-authenticated GitHub Actions. This removes Terraform state-storage costs (~$5/month) and halves CI/CD deploy time.
3. **Cost-Effective SKUs by Default** – Deployment parameters default to:
   • App Service Plan **B1** in non-prod environments, **S1** in prod
   • PostgreSQL **Burstable B1ms** for dev/test, **GeneralPurpose GP_G4** for prod
   • Redis **Basic C0 250 MB** for dev/test, **Standard C1 1 GB** for prod
   These defaults are centrally managed in `infrastructure/bicep/parameters.bicepparam`.

All CI/CD workflows and deployment scripts were updated to reference the new single resource group and Bicep templates (`infrastructure/bicep`).

> 🔄 **Migration impact:** No downtime. All existing resources were moved into `vigor-rg` via `az resource move`, and Terraform state storage was deleted.

## 2. System Architecture

### 2.1 Infrastructure Migration Timeline (December 2024)

**December 6-8, 2024: Complete Infrastructure Overhaul**

**Day 1 (Dec 6): Documentation Cleanup & Preparation**

- ✅ Removed 20+ redundant documentation files
- ✅ Enhanced PROJECT_METADATA.md with 1,402 lines of comprehensive documentation
- ✅ Consolidated admin workflow patterns and cost-effective provider hierarchy
- ✅ Organized docs/ folder structure (5 essential files retained)

**Day 2 (Dec 7): Infrastructure Migration Planning**

- ✅ Created complete Azure Bicep templates (353 lines)
- ✅ Developed migration scripts with comprehensive validation workflow
- ✅ Updated GitHub Actions pipeline for Bicep deployment
- ✅ Prepared environment validation and deployment procedures

**Day 3 (Dec 8): Authentication Fix & Final Migration**

- ✅ Created new Azure Service Principal: "vigor-cicd-sp"
- ✅ Configured OIDC federated identity credentials for GitHub Actions
- ✅ Updated GitHub repository secrets with proper OIDC authentication
- ✅ Resolved CI/CD pipeline authentication issues
- ✅ Completed migration scripts and documentation

**Migration Benefits Achieved:**

- 🚀 **Faster Deployments**: No state management overhead
- 💰 **Cost Savings**: Eliminated Terraform state storage (~$5/month)
- 🔒 **Better Azure Integration**: Native Bicep ARM template compilation
- 📝 **Cleaner Templates**: More readable infrastructure code
- 🎯 **Native Azure Features**: Direct support for latest Azure services

### 2.2 Current Authentication & Security Configuration

**Azure Service Principal Details:**

- **Name**: vigor-cicd-sp
- **Client ID**: 42aae4cc-5dd0-4469-9f10-87e45dc45088
- **Tenant ID**: 80fe68b7-105c-4fb9-ab03-c9a818e35848
- **Subscription ID**: 8c48242c-a20e-448a-ac0f-be75ac5ebad0
- **Resource Group**: vigor-rg
- **Role**: Contributor (resource group scoped)

**Federated Identity Credentials:**

- **Main Branch**: `repo:vedprakash-m/vigor:ref:refs/heads/main`
- **Pull Requests**: `repo:vedprakash-m/vigor:pull_request`
- **Authentication Method**: OIDC (OpenID Connect) - no client secrets required

**GitHub Secrets Configuration (Updated Dec 8, 2024):**

```bash
# Azure Authentication (OIDC-based)
AZURE_CLIENT_ID=42aae4cc-5dd0-4469-9f10-87e45dc45088
AZURE_TENANT_ID=80fe68b7-105c-4fb9-ab03-c9a818e35848
AZURE_SUBSCRIPTION_ID=8c48242c-a20e-448a-ac0f-be75ac5ebad0

# Container Registry
ACR_LOGIN_SERVER=vigoracr.azurecr.io
ACR_USERNAME=(auto-generated)
ACR_PASSWORD=(auto-generated)

# Application Secrets
POSTGRES_ADMIN_PASSWORD=(secure-generated)
SECRET_KEY=(jwt-secret-key)
ADMIN_EMAIL=admin@vigor-fitness.com

# Optional AI Provider Keys
OPENAI_API_KEY=(optional)
GEMINI_API_KEY=(optional)
PERPLEXITY_API_KEY=(optional)
```

### 2.3 Bicep Infrastructure Templates

**Main Infrastructure Components (`infrastructure/bicep/main.bicep`):**

```bicep
// Production-grade Azure Bicep template with 353 lines
// Features: Cost optimization, security, scalability

// Core Resources
- Resource Group: vigor-rg
- App Service Plan: Standard S1 (production), Basic B1 (development)
- App Service: Linux-based Python 3.11 runtime
- Static Web App: Global CDN with East US2 deployment
- PostgreSQL: Flexible server with configurable tiers
- Redis Cache: Standard/Basic tier with TLS encryption
- Key Vault: Secret management with managed identity access
- Container Registry: Premium (production) / Standard (development)
- Application Insights: Performance monitoring
```

**Deployment Configuration (`infrastructure/bicep/parameters.bicepparam`):**

```bicep
// Environment-specific parameters
param environment = 'prod'
param location = 'East US'
param appName = 'vigor'
param appServiceSku = 'S1'          // Standard tier for production
param redisCapacity = 1             // 1GB cache
param postgresStorageMb = 10240     // 10GB PostgreSQL storage
```

**Deployment Scripts:**

- `infrastructure/bicep/deploy.sh`: Automated deployment with validation
- `scripts/migrate-to-bicep.sh`: Complete migration workflow
- Environment variable validation and secure secret management

### 2.4 Database Schema & LLM Integration

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

### 2.5.1 Updated Pipeline Overview (December 2024)

The Vigor application utilizes a modernized GitHub Actions CI/CD pipeline with Azure Bicep infrastructure deployment, OIDC authentication, and enterprise-level security practices.

**Pipeline Status**: ✅ **FULLY FUNCTIONAL** (Fixed December 8, 2024)

**Key Updates:**

- **Authentication**: Migrated from client-secret to OIDC federated identity
- **Infrastructure**: Replaced Terraform with Azure Bicep deployment
- **Cost Optimization**: Eliminated Terraform state storage requirements
- **Security**: Enhanced with managed identities and Key Vault integration

### 2.5.2 Pipeline Jobs Architecture (12 Comprehensive Jobs)

**Security-First Pipeline Flow:**

1. **Security Scanning** ✅

   - Trivy vulnerability scanner with SARIF upload
   - Critical vulnerabilities block deployment
   - GitHub Security tab integration

2. **Backend Quality & Testing** ✅

   - Bandit security analysis
   - Pytest with coverage reporting
   - Black code formatting validation
   - Safety dependency scanning

3. **Frontend Quality & Testing** ✅

   - ESLint code quality checks
   - TypeScript compilation validation
   - Jest unit testing with coverage
   - npm audit security scanning

4. **Infrastructure Validation** ✅

   - Azure Bicep template validation
   - OIDC authentication verification
   - Resource cost estimation
   - Deployment readiness checks

5. **Container Build & Registry** ✅

   - Multi-stage Docker builds
   - Image optimization and layer caching
   - Azure Container Registry push
   - Security scanning of container images

6. **Infrastructure Deployment** ✅

   - Azure Bicep template deployment
   - Resource group and service provisioning
   - Key Vault secret configuration
   - Application configuration deployment

7. **Application Deployment** ✅

   - Backend deployment to Azure App Service
   - Frontend deployment to Static Web App
   - Environment-specific configuration injection
   - Health check validation

8. **Post-Deployment Validation** ✅
   - API endpoint health checks
   - Database connectivity verification
   - Application startup validation
   - Performance baseline establishment

### 2.5.3 Branch Strategy & Environment Mapping

**Enhanced Deployment Strategy:**

```yaml
# Updated Branch Mapping (December 2024)
main branch → Production Environment:
  - Automatic Bicep infrastructure deployment
  - Full security scanning and quality gates
  - Zero-downtime deployment with health checks
  - Cost-optimized resource allocation

pull_request → Preview Environments:
  - Infrastructure validation (no deployment)
  - Security and quality gate enforcement
  - Code coverage and test validation
  - Cost estimation and optimization suggestions
```

### 2.5.4 Security Implementation Updates

**Enhanced Security Scanning:**

- **Container Security**: Trivy scans with severity-based blocking
- **Code Security**: Bandit static analysis with custom rule sets
- **Infrastructure Security**: Azure Policy compliance validation
- **Dependency Security**: Automated vulnerability patching with Dependabot
- **Secrets Management**: Azure Key Vault with system-assigned managed identities

**OIDC Security Benefits:**

- **No Long-Lived Secrets**: Eliminated client secrets from GitHub
- **Short-Lived Tokens**: Automatic token rotation and expiration
- **Audit Trail**: Enhanced Azure AD integration and logging
- **Reduced Attack Surface**: Federated identity with minimal permissions

### 2.5.5 Azure Infrastructure Integration Updates

**Bicep Infrastructure as Code (Replaced Terraform):**

```bicep
// Bicep Template Architecture
infrastructure/bicep/
├── main.bicep              # Main infrastructure template (353 lines)
├── parameters.bicepparam   # Environment-specific parameters
├── deploy.sh              # Automated deployment script
└── README.md              # Comprehensive deployment documentation
```

**Azure Services Integration (Updated December 2024):**

- **Azure Container Registry**: Enhanced with zone redundancy and security
- **Azure App Service**: Linux-based with managed identity integration
- **Azure Key Vault**: Automated secret management with policy-based access
- **Azure PostgreSQL**: Flexible server with configurable performance tiers
- **Azure Application Insights**: Real-time monitoring with custom dashboards

**Cost Optimization Achievements:**

- **Terraform State Storage**: Eliminated (~$5)
- **Container Registry**: Zone redundancy only in production
- **Database Tier Optimization**: B1ms for development, GP for production
- **Static Web App**: Free tier for development environments

### 2.5.6 Deployment Strategies

**Production Deployment Process (Updated):**

1. **Pre-Deployment Validation**

   - OIDC token acquisition and validation
   - Azure resource health verification
   - Bicep template syntax and policy validation
   - Cost impact analysis and approval gates

2. **Infrastructure Deployment**

   - Bicep template deployment with incremental updates
   - Resource dependency resolution and ordering
   - Configuration drift detection and remediation
   - Post-deployment resource verification

3. **Application Deployment**

   - Container image deployment to App Service
   - Static assets deployment to CDN
   - Environment-specific configuration injection
   - Database migration execution (if required)

4. **Health Validation & Monitoring**
   - API endpoint availability verification
   - Performance baseline establishment
   - Error rate monitoring and alerting
   - User experience validation checkpoints

**Rollback Procedures (Enhanced):**

- **Automatic Triggers**: Health check failures, error rate spikes
- **Manual Rollback**: GitHub Actions workflow dispatch
- **Infrastructure Rollback**: Bicep template version reversion
- **Data Protection**: Automated backup validation before deployments

### 2.5.7 Monitoring & Observability

**Pipeline Monitoring (Enhanced December 2024):**

- **OIDC Authentication**: Token acquisition and renewal monitoring
- **Bicep Deployment**: Template validation and resource creation tracking
- **Cost Tracking**: Real-time Azure spend monitoring and alerting
- **Security Posture**: Continuous compliance and vulnerability assessment

**Application Monitoring Integration:**

- **Azure Application Insights**: Performance metrics and custom dashboards
- **Log Analytics**: Centralized logging with intelligent alerting
- **Health Endpoints**: Comprehensive application health monitoring
- **User Experience**: Real user monitoring and synthetic transactions

### 2.5.8 Secrets & Configuration Management

**Enhanced GitHub Secrets (OIDC-based):**

```bash
# Azure Authentication (No client secrets required)
AZURE_CLIENT_ID=42aae4cc-5dd0-4469-9f10-87e45dc45088
AZURE_TENANT_ID=80fe68b7-105c-4fb9-ab03-c9a818e35848
AZURE_SUBSCRIPTION_ID=8c48242c-a20e-448a-ac0f-be75ac5ebad0

# Application Configuration
POSTGRES_ADMIN_PASSWORD=(auto-generated secure password)
SECRET_KEY=(JWT signing key)
ADMIN_EMAIL=admin@vigor-fitness.com

# Optional AI Provider Keys
GEMINI_API_KEY=(cost-effective primary provider)
OPENAI_API_KEY=(premium quality option)
PERPLEXITY_API_KEY=(balanced performance option)
```

**Azure Key Vault Integration:**

- **System-Assigned Managed Identity**: App Service automatic access
- **Secret Rotation**: Automated key rotation and lifecycle management
- **Access Policies**: Principle of least privilege with audit logging
- **Network Security**: Private endpoint integration and firewall rules

### 2.5.9 Cost Optimization Achievements

**Infrastructure Cost Reduction:**

- **Terraform State Storage**: Eliminated (~$5)
- **Container Registry**: Zone redundancy only in production
- **Database Tier Optimization**: B1ms for development, GP for production
- **Static Web App**: Free tier for development environments

**Pipeline Efficiency Improvements:**

- **Bicep Compilation**: Faster than Terraform planning and applying
- **Parallel Job Execution**: Optimized dependency chains
- **Container Layer Caching**: Reduced build and deployment times
- **Resource Cleanup**: Automated orphaned resource detection

**Monthly Cost Estimate (Optimized):**

```
Production Environment: $150-180/month
├── App Service Plan (S1): $73/month
├── PostgreSQL (10GB): $45-65/month
├── Redis (1GB Standard): $25/month
├── Static Web App: $10/month
├── Storage & Monitoring: $5-15/month
└── Terraform State Storage: $0 (eliminated)

Development Environment: $25-35/month
├── App Service Plan (B1): $15/month
├── PostgreSQL (5GB): $8-12/month
├── Redis (Basic): $8/month
├── Static Web App: $0 (Free tier)
└── Storage & Monitoring: $2-5/month
```

### 2.5.10 Disaster Recovery & Business Continuity

**Enhanced Backup Strategy:**

- **Database Backups**: Automated PostgreSQL backups with 35-day retention
- **Container Images**: Registry replication with retention policies
- **Infrastructure Templates**: Version-controlled Bicep templates in Git
- **Configuration Backup**: Key Vault secret versioning and recovery

**Incident Response (Updated):**

- **OIDC Token Issues**: Automatic token refresh and fallback procedures
- **Bicep Deployment Failures**: Template rollback and resource cleanup
- **Application Health**: Automated scaling and traffic routing
- **Security Incidents**: Managed identity revocation and audit trail

### 2.5.11 Migration Summary & Lessons Learned

**Terraform to Bicep Migration (December 6-8, 2024):**

**✅ Successfully Completed:**

- Infrastructure template conversion (Terraform → Bicep)
- Authentication modernization (client-secret → OIDC)
- CI/CD pipeline updates and validation
- Cost optimization and resource cleanup
- Documentation updates and workflow standardization

**🔧 Key Improvements Achieved:**

1. **Simplified Infrastructure**: No state management complexity
2. **Enhanced Security**: OIDC authentication with managed identities
3. **Cost Reduction**: Eliminated Terraform backend storage costs
4. **Better Developer Experience**: Native Azure tooling integration
5. **Faster Deployments**: Direct ARM template compilation

**📚 Documentation Updates:**

- PROJECT_METADATA.md: Comprehensive status and architecture documentation
- DEPLOYMENT_GUIDE.md: Updated with Bicep procedures
- Infrastructure README: Complete Bicep deployment instructions
- Migration scripts: Automated Terraform to Bicep conversion tools

**🎯 Next Phase Priorities:**

1. **Application Feature Development**: Resume MVP feature completion
2. **Performance Optimization**: Application-level optimizations
3. **User Testing**: Beta user recruitment and feedback collection
4. **Mobile Responsiveness**: Enhanced mobile web experience
5. **Analytics Implementation**: User behavior tracking and optimization

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

**Admin System Features:**

- **Priority-Based Fallback**: Automatic provider switching based on availability and cost optimization
- **Real-Time Budget Controls**: Weekly/monthly spending limits with auto-disable functionality
- **Cost-Effective Provider Hierarchy**:
  - Google Gemini Flash 2.5: $0.075/$0.30 per 1M tokens (most cost-effective)
  - GPT-4o Mini: $0.15/$0.60 per 1M tokens (great OpenAI value)
  - Perplexity Llama 3.1: $0.20/$0.20 per 1M tokens (good balance)
  - GPT-4o: $2.50/$10.00 per 1M tokens (premium quality)
- **Default Configuration**: Gemini Flash primary, Perplexity backup, $10/week budget
- **Admin Access**: Username-based admin detection (contains 'admin'), comprehensive control panel

**Business Model Alignment:**

- **Tier-Based Architecture**: Three-tier freemium model (FREE/PREMIUM/UNLIMITED) with clear upgrade incentives
- **Usage-Based Billing**: Real-time cost tracking and budget enforcement per user tier
- **Enterprise-Ready**: Admin dashboard, comprehensive analytics, and system management capabilities

## 6. Architecture Transition Documentation

### 6.1 Container to App Service + Functions Migration (June 2025)

#### 6.1.1 Decision Background

**Previous Architecture Challenges:**

- Persistent issues with Azure Container Registry (ACR) in CI/CD pipelines
- Failed deployments due to ACR connectivity and authentication problems
- Higher costs associated with maintaining container infrastructure
- Increased operational complexity for development team

**Alternatives Considered:**

1. **Continue with ACR and fix issues**: Extensive troubleshooting required
2. **Move to GitHub Container Registry**: Simpler but still container-based
3. **App Service + Functions**: More managed with cost benefits

#### 6.1.2 Decision Rationale

The team evaluated options based on:

- **Cost**: App Service + Functions provides 15-30% cost reduction
- **Simplicity**: Eliminates container registry management
- **Operational overhead**: Reduces DevOps maintenance burden
- **Scalability**: Functions provide better auto-scaling for variable workloads

**Decision Date**: June 14, 2025
**Decision Maker**: Engineering and DevOps team

#### 6.1.3 Implementation Plan

**Phase 1: Infrastructure Update (Current)**

- Create Azure Function App for AI processing workloads
- Update App Service configuration for direct code deployment
- Establish Static Web App for frontend hosting
- Update Bicep templates and deployment pipeline

**Phase 2: Codebase Adaptation**

- Refactor AI processing code into Azure Functions
- Update frontend build configuration for Static Web Apps
- Modify backend environment configuration
- Update logging and monitoring integration

**Phase 3: Migration & Validation**

- Deploy backend directly to App Service
- Deploy AI Functions
- Deploy frontend to Static Web Apps
- Validate system functionality and performance

**Phase 4: Cleanup & Documentation**

- Remove container-specific configurations
- Update documentation and runbooks
- Optimize CI/CD pipeline for new architecture

#### 6.1.4 Current Status & Issues

**Status**: Phase 2 in progress (June 14, 2025)
**Completed**:

- Initial infrastructure planning
- Created Bicep templates for App Service, Function App, and Static Web App
- Fixed CI/CD pipeline issues:
  - Resolved composite action secret handling
  - Fixed Bicep validation errors
  - Optimized security scanning
- Migrated AI code to Azure Functions:
  - Created shared LLM provider code for Functions
  - Implemented three core AI Functions: GenerateWorkout, AnalyzeWorkout, CoachChat
  - Added proper authentication between services using managed identities
  - Implemented cold start mitigation and performance monitoring

**In Progress**:

- Testing the integration between App Service and Functions
- Performance tuning and optimization
- Comprehensive migration validation

**Issues & Risks**:

- Cold start performance requires monitoring in production
- Authentication between services requires Azure-specific configuration
- Security scanning optimization needs validation
