# Vigor Fitness Platform - Project Metadata

_Last updated: 2025-06-16_

---

## 📋 Overview

**Vigor** is a modern fitness platform with AI-powered workout generation and coaching features. Built with clean architecture principles, cost-optimized for single-slot deployment, and designed for scalability.

**Tech Stack**: React + TypeScript frontend, FastAPI + Python backend, PostgreSQL database, Azure cloud deployment.

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
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Azure Static   │    │   PostgreSQL    │    │  Azure Services │
│    Web App      │    │   Database      │    │   (Key Vault)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Design Principles

1. **Clean Architecture**: Domain, Application, Infrastructure layers
2. **Cost Optimization**: Single-slot deployment, Basic SKUs
3. **Provider Agnostic**: Seamless AI provider switching
4. **Progressive Enhancement**: Works without AI (fallback mode)

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

_This document serves as the single source of truth for the Vigor project. All architectural decisions, deployment strategies, and development workflows are documented here._
