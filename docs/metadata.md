# Vigor Fitness Platform - Project Metadata

_Last updated: 2025-01-20_

---

## 📋 Overview

**Vigor** is a modern fitness platform with AI-powered workout generation and coaching features. Built with clean architecture principles, cost-optimized for single-slot deployment, and designed for scalability.

**Tech Stack**: React + TypeScript frontend, FastAPI + Python backend, PostgreSQL database, Azure cloud deployment.

**Current Status**: Production Readiness Implementation Phase
**Target Launch**: 8 weeks from implementation start

---

## 🚨 Production Readiness Implementation Status

### Current Phase: Testing & Quality Enhancement (Phase 2)

**Timeline**: Week 3-4 | **Status**: Starting Implementation

#### ✅ Phase 1 COMPLETE - Critical Security & Stability

- [x] Rate limiting implementation (SlowAPI with Redis/memory backend) ✅
- [x] Comprehensive input validation framework (XSS, SQL injection prevention) ✅
- [x] Enhanced security headers (CSP, HSTS, CSRF protection) ✅
- [x] Security audit logging system for all events ✅
- [x] Enhanced authentication service with secure token management ✅
- [x] Global error handling with production-safe responses ✅
- [x] Health check endpoint with dependency monitoring ✅
- [x] Request validation and origin checking ✅
- [x] **Python 3.9 compatibility resolution** ✅ **CRITICAL FIX COMPLETE**

#### 🔄 Phase 2 IN PROGRESS - Testing & Quality (80% Coverage Target)

**Current Focus**: Backend testing enhancement (50% → 80%)

**Daily Implementation Plan:**

- **Day 1**: Backend test suite expansion (authentication, security, core APIs)
- **Day 2**: Frontend test suite expansion (components, services, user flows)
- **Day 3**: Integration testing for security features and rate limiting
- **Day 4**: E2E testing for critical user paths and admin workflows
- **Day 5**: Performance testing, load testing, and benchmarking

**Target Metrics:**

- Backend Test Coverage: 50% → **80%**
- Frontend Test Coverage: 8.76% → **80%**
- E2E Critical Path Coverage: 0% → **90%**
- API Response Time: Unknown → **<200ms**
- Load Testing: None → **1000 concurrent users**

#### 📋 Phase 3 Planned - Performance & Monitoring

- [ ] Advanced monitoring dashboards
- [ ] Performance optimization (database, caching)
- [ ] Real-time analytics and alerting
- [ ] CDN integration and asset optimization

#### 📋 Phase 4 Planned - Production Hardening

- [ ] Security penetration testing
- [ ] Container optimization and scanning
- [ ] Deployment automation improvements
- [ ] Documentation finalization

### Implementation Phases Overview

| Phase       | Timeline | Focus Area                       | Status             |
| ----------- | -------- | -------------------------------- | ------------------ |
| **Phase 1** | Week 1-2 | Critical Security & Stability    | ✅ **COMPLETE**    |
| **Phase 2** | Week 3-4 | Testing & Quality (80% coverage) | 🔄 **IN PROGRESS** |
| **Phase 3** | Week 5-6 | Performance & Monitoring         | 📋 Planned         |
| **Phase 4** | Week 7-8 | Production Hardening             | 📋 Planned         |

---

## 🚀 Quick Start

### Prerequisites

- Python 3.12+, Node.js 20+, Git
- Azure subscription (for cloud deployment)

### Local Development

```bash
# Using VS Code Tasks (recommended)
1. Task: Install All Dependencies
2. Task: Start Backend Server
3. Task: Start Frontend Dev Server

# Manual setup
cd backend && python -m venv venv && source venv/bin/activate
pip install -r requirements.txt && python main.py

cd frontend && npm install && npm run dev
```

**Access**: Frontend at http://localhost:5173, Backend at http://localhost:8000
**Default Admin**: admin@vigor.com / admin123!

---

## 📖 Architectural Decisions (ADRs)

| ID       | Date       | Decision                                                         | Rationale                              |
| -------- | ---------- | ---------------------------------------------------------------- | -------------------------------------- |
| ADR-0008 | 2025-06-16 | **CI/CD Simplification**: Single-slot cost-optimized deployment  | Reduce costs from $96 to $43/month     |
| ADR-0007 | 2025-06-16 | **Local Validation**: Enhanced E2E validation matching CI/CD     | Fix validation gaps                    |
| ADR-0006 | 2025-06-15 | **CI/CD**: Unified pipeline replacing separate workflows         | Proper orchestration, failure handling |
| ADR-0005 | 2025-06-15 | **Resources**: Static naming (vigor-backend, vigor-db, vigor-kv) | Idempotency and clarity                |
| ADR-0004 | 2025-06-15 | **Deployment**: Single environment, single slot strategy         | Keep costs under $50/month             |
| ADR-0003 | 2025-06-15 | **Infrastructure**: Single resource group vigor-rg               | Cost control, simplified operations    |
| ADR-0002 | 2025-06-15 | **Documentation**: Track via docs/metadata.md + ADRs             | Single source of truth                 |
| ADR-0001 | 2025-06-15 | **Architecture**: Clean/Hexagonal Architecture adoption          | Testability, scalability, modularity   |

---

## 🗺️ Project Roadmap

### ✅ Completed (Phases 0-3)

- [x] **Clean Architecture**: Extracted LLM gateway components (request_validator, routing_engine, budget_enforcer, response_recorder)
- [x] **Quality Gates**: Pre-commit hooks, linting, testing (coverage: backend 50%+, frontend 31%+)
- [x] **Data Layer**: Repository pattern, Pydantic schemas, removed direct ORM access
- [x] **Observability**: OpenTelemetry tracing, structured logging, background workers
- [x] **CI/CD Optimization**: Simplified from complex staging pipeline to cost-optimized single-slot deployment

### 🔄 In Progress (Phase 4)

- [x] **Frontend Structure**: Feature-sliced organization, Zustand state management
- [ ] **Test Coverage**: Increase to 80% for both frontend and backend

### 📋 Planned (Phase 5)

- [ ] **DevOps**: Multi-stage Dockerfiles, Dependabot, license scanning
- [ ] **Performance**: Caching optimization, CDN integration
- [ ] **Security**: Enhanced vulnerability scanning

---

## 💰 Infrastructure & Deployment

### Cost-Optimized Azure Architecture

**Resource Groups:**

- `vigor-rg`: All compute and storage resources

**Resources & Monthly Costs:**

- **App Service Basic B1**: ~$13/month (backend API)
- **PostgreSQL Flexible Basic**: ~$25/month (database)
- **Key Vault Standard**: ~$3/month (secrets)
- **Storage Account LRS**: ~$2/month (static assets)
- **Static Web App**: Free tier (frontend)

**Total: ~$43/month** (55% cost reduction from previous $96/month)

### Deployment Strategy

- **Single Environment**: Production only (no staging)
- **Single Slot**: No deployment slots for cost savings
- **Direct Deployment**: CI/CD deploys directly to production
- **Infrastructure as Code**: Azure Bicep templates

### CI/CD Pipeline (Simplified)

```
Quality Checks → Build → Deploy Production → Health Check
```

**File**: `.github/workflows/simple-deploy.yml`

- Combined frontend/backend validation
- Direct production deployment
- Simple health verification
- ~5-10 minute runtime vs 30+ minutes previously

---

## 🔧 Development Workflow

### Local Validation

```bash
# Before committing, run:
./scripts/enhanced-local-validation.sh

# Includes:
# - Backend: black, isort, ruff, pytest (coverage ≥50%)
# - Frontend: eslint, typescript, jest (coverage ≥31%)
# - Optional: E2E tests with --include-e2e flag
```

### Testing Strategy

- **Backend**: pytest with coverage reporting, integration tests
- **Frontend**: Jest unit tests, Playwright E2E tests
- **API**: FastAPI test client, OpenAPI validation
- **E2E**: Cross-browser testing, mobile viewport testing

### Code Quality

- **Formatting**: Black (Python), Prettier (TypeScript)
- **Linting**: Ruff (Python), ESLint (TypeScript)
- **Type Checking**: mypy (Python), TypeScript compiler
- **Security**: Bandit, Safety, Gitleaks, TruffleHog

---

## 🔒 Security & Configuration

### Environment Variables

```bash
# Required for production
DATABASE_URL=postgresql://user:pass@host:5432/vigor
SECRET_KEY=your-jwt-signing-key-minimum-32-characters
ADMIN_EMAIL=admin@yourdomain.com

# AI Providers (optional)
OPENAI_API_KEY=sk-...
LLM_PROVIDER=openai|gemini|perplexity|fallback
```

### AI Provider Support

- **OpenAI GPT**: Primary AI provider
- **Google Gemini**: Alternative provider
- **Perplexity**: Research-focused AI
- **Fallback Mode**: Basic responses without AI

---

## 🎯 Key Features

### Core Functionality

- **User Management**: JWT authentication, tier-based access
- **Workout Generation**: AI-powered personalized workouts
- **Progress Tracking**: Exercise logs, streak tracking
- **Coach Chat**: AI fitness coaching interface
- **Nutrition Guidance**: Meal planning and dietary advice

### Technical Features

- **PWA Support**: Offline capability, mobile app-like experience
- **Responsive Design**: Mobile-first, works on all devices
- **Real-time Updates**: WebSocket connections for live features
- **Caching**: Redis for session management and response caching
- **Monitoring**: Application Insights, health checks, error tracking

---

## 📁 Project Structure

```
vigor/
├── backend/              # FastAPI application
│   ├── api/             # REST API endpoints
│   ├── application/     # Application services (Clean Architecture)
│   ├── core/            # Business logic and entities
│   ├── database/        # Database models and repositories
│   ├── domain/          # Domain models and interfaces
│   └── infrastructure/  # External service adapters
├── frontend/            # React TypeScript application
│   ├── src/
│   │   ├── components/  # Reusable UI components
│   │   ├── pages/       # Route components
│   │   ├── services/    # API client and external services
│   │   ├── stores/      # Zustand state management
│   │   └── types/       # TypeScript type definitions
├── functions/           # Azure Functions (AI processing)
├── infrastructure/      # Azure Bicep IaC templates
├── scripts/            # Development and deployment scripts
└── docs/               # Project documentation
```

---

## 🛠️ Maintenance & Operations

### Monitoring

- **Health Endpoint**: `/health` for deployment verification
- **Metrics**: Application Insights for performance monitoring
- **Logs**: Structured logging with OpenTelemetry tracing
- **Alerts**: Automated failure notifications via GitHub issues

### Backup Strategy

- **Database**: Automated Azure PostgreSQL backups (7-day retention)
- **Code**: Git repository with branch protection
- **Secrets**: Azure Key Vault with access logging
- **Infrastructure**: Version-controlled Bicep templates

### Performance Optimization

- **Frontend**: Vite build optimization, lazy loading, tree shaking
- **Backend**: FastAPI async operations, database indexing
- **Caching**: Response caching, static asset CDN
- **Database**: Connection pooling, query optimization

---

## 🚨 Known Issues & Risks

### Current Issues

- **Test Coverage**: Frontend at 31% (target: 80%)
- **Error Handling**: Need enhanced error boundaries
- **Mobile UX**: Some components need mobile optimization

### Risk Mitigation

- **API Changes**: Contract testing prevents breaking changes
- **Database Migration**: Alembic migrations with rollback capability
- **Deployment Failure**: Automated rollback via emergency workflow
- **Security**: Regular dependency updates, vulnerability scanning

---

## 📞 Support & Resources

### Documentation

- **API Documentation**: `/docs` endpoint (OpenAPI/Swagger)
- **Architecture Decisions**: `docs/adr/` directory
- **Development Guide**: `docs/CONTRIBUTING.md`
- **Security Guide**: `docs/secrets_management_guide.md`

### Key Scripts

- **Local Validation**: `scripts/enhanced-local-validation.sh`
- **Health Check**: `scripts/health-check.sh`
- **E2E Testing**: `scripts/test-e2e-local.sh`
- **Setup Secrets**: `scripts/setup-github-secrets.sh`

### External Dependencies

- **Frontend**: React 18, TypeScript 5, Chakra UI, Zustand
- **Backend**: FastAPI, SQLAlchemy, Alembic, Pydantic, JWT
- **Infrastructure**: Azure App Service, PostgreSQL, Key Vault
- **AI**: OpenAI GPT, Google Gemini, Perplexity APIs

---

## 🚨 Production Readiness Metrics

### Security Metrics ✅ PHASE 1 COMPLETE

- **API Rate Limiting**: ✅ **COMPLETE** - 5-100 req/min by endpoint type
- **Input Validation**: ✅ **COMPLETE** - XSS, SQL injection, and data validation
- **Error Handling**: ✅ **COMPLETE** - Standardized with audit logging
- **Secrets Security**: ✅ **COMPLETE** - JWT with secure token management
- **Security Headers**: ✅ **COMPLETE** - CSP, HSTS, CSRF protection
- **Audit Logging**: ✅ **COMPLETE** - All security events tracked

### Quality Metrics 🔄 PHASE 2 IN PROGRESS

- **Backend Test Coverage**: 50% → **80% target**
- **Frontend Test Coverage**: 8.76% → **80% target**
- **E2E Test Coverage**: Minimal → **Critical paths covered**
- **Integration Tests**: None → **Security features covered**
- **Performance Tests**: None → **Load testing complete**
- **API Response Time**: Unknown → **<200ms target**

### Stability Metrics 📋 PHASE 3 PLANNED

- **Health Checks**: ✅ Basic → **Multi-service monitoring**
- **Error Rate**: Unknown → **<0.1% target**
- **Uptime**: Unknown → **99.9% target**
- **Database Performance**: Unknown → **Optimized with pooling**

---

## 🎯 Production Launch Criteria

### 🔴 Blocking (Must Complete)

- [x] All API endpoints rate limited ✅
- [x] 100% input validation coverage ✅
- [x] Standardized error handling ✅
- [x] Enhanced JWT token management ✅
- [x] Security audit logging ✅
- [x] Health checks implemented ✅
- [ ] 80%+ test coverage (backend & frontend) 🔄 **IN PROGRESS**
- [ ] Security penetration testing passed
- [ ] Load testing completed
- [ ] Performance benchmarks met

### 🟡 Important (Nice to Have)

- [ ] Progressive Web App features
- [ ] Real-time coaching WebSocket
- [ ] Advanced monitoring dashboards
- [ ] Performance optimization complete

---

## 🏗️ System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend │    │  FastAPI Backend │    │  AI Providers   │
│                 │    │                 │    │                 │
│ • Chakra UI     │◄───┤ • JWT Auth      │◄───┤ • OpenAI        │
│ • TypeScript    │    │ • User Tiers    │    │ • Gemini        │
│ • PWA Ready     │    │ • Usage Tracking│    │ • Perplexity    │
│ • Mobile-First  │    │ • LLM Abstraction│    │ • Fallback Mode │
│ • Rate Limited  │    │ • Rate Limiting │    │ • Circuit Break │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Azure Static   │    │   PostgreSQL    │    │  Azure Services │
│    Web App      │    │   Database      │    │   (Key Vault)   │
│  + Health Check │    │  + Conn Pool    │    │  + Monitoring   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Production Security Enhancements

1. **API Protection**: Rate limiting, input validation, CORS hardening
2. **Data Security**: Database connection pooling, encrypted connections
3. **Secrets Management**: 100% Azure Key Vault integration
4. **Monitoring**: Comprehensive health checks and error tracking

---

_This document serves as the single source of truth for the Vigor project. All architectural decisions, deployment strategies, and development workflows are documented here._
