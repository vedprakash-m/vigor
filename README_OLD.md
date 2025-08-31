# 🏋️‍♂️ Vigor - Modernized AI Fitness Platform

> **AI-powered fitness coaching with personalized workout generation and progress tracking.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![React 19](https://img.shields.io/badge/react-19-blue.svg)](https://reactjs.org/)
[![Azure Functions](https://img.shields.io/badge/Azure%20Functions-Serverless-green.svg)](https://azure.microsoft.com/en-us/services/functions/)
[![Cosmos DB](https://img.shields.io/badge/Cosmos%20DB-NoSQL-blue.svg)](https://azure.microsoft.com/en-us/services/cosmos-db/)

---

## ✨ Overview

**Vigor** is a modernized AI-powered fitness platform built with serverless architecture. The application provides personalized workout generation, AI coaching conversations, and comprehensive progress tracking through a cost-optimized, scalable infrastructure.

### Key Features

- **🤖 AI Fitness Coach** - Conversational coaching powered by Google Gemini Flash 2.5
- **📋 Personalized Workouts** - AI-generated workout plans based on user goals and available equipment
- **📊 Progress Tracking** - Comprehensive analytics with workout logs and performance metrics
- **💬 Interactive Coaching** - Real-time chat interface for fitness guidance and form tips
- **📱 Mobile-First Design** - Responsive interface optimized for mobile devices
- **🔐 Secure Authentication** - Microsoft Entra ID integration with email-based user management

### Modernized Architecture (2025)

The application has been completely modernized with a serverless-first approach:

- **Backend:** Azure Functions (Python 3.11) with Flex Consumption Plan
- **Frontend:** React 19 + TypeScript + Chakra UI v3 + MSAL.js
- **Database:** Azure Cosmos DB (NoSQL) with email-based user identification
- **Authentication:** Microsoft Entra ID default tenant with JWT validation
- **AI Provider:** Google Gemini Flash 2.5 (single provider for cost efficiency)
- **Infrastructure:** Single unified Azure resource group with Bicep IaC
- **Cost Model:** Consumption-based pricing (~$30-50/month vs ~$100/month legacy)

---

## 🏗️ Architecture Overview

### Unified Resource Group Design

```
vigor-rg (West US 2)
├── Azure Functions (vigor-backend)     # Serverless API
├── Cosmos DB (vigor-cosmos-prod)       # NoSQL database
├── Key Vault (vigor-kv-*)              # Secrets management
├── Application Insights (vigor-insights) # Monitoring
└── Storage Account (vigorstorage*)     # Function app storage
```

### Database Schema (Cosmos DB)

- **users**: Email-based user profiles with fitness preferences
- **workouts**: AI-generated workout plans with exercise details
- **workout_logs**: User progress tracking and completion data
- **ai_coach_messages**: Chat history and coaching conversations

---

## 🚀 Quick Start

### Prerequisites

- Python 3.11+, Node.js 18+, Git
- Azure subscription and CLI for cloud deployment
- Azure Functions Core Tools (for local Functions development)

### Local Development Setup

**Option 1: Legacy Backend (FastAPI) + Frontend**

```bash
# Backend setup
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
LLM_PROVIDER=fallback python main.py  # http://localhost:8000

# Frontend setup (new terminal)
cd frontend
npm install
npm run dev  # http://localhost:5173
```

**Option 2: Modernized Functions + Frontend**

```bash
# Azure Functions setup
cd functions-modernized
func start  # Requires Azure Functions Core Tools

# Frontend setup (new terminal)
cd frontend
npm install
npm run dev  # http://localhost:5173
```

**Option 3: VS Code Tasks**

1. Open project in VS Code
2. **Ctrl+Shift+P** → "Tasks: Run Task"
3. Choose: "Start Backend Server" or "Start Frontend Dev Server"

```bash
# Backend setup
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
LLM_PROVIDER=fallback python main.py  # http://localhost:8000

# Frontend setup (new terminal)
cd frontend && npm install && npm run dev  # http://localhost:5173
```

**🔑 Default Credentials:** `admin@vigor.com` / `admin123!`

### Docker Alternative

```bash
docker-compose up -d
# Access at http://localhost:5173
```

---

## 🧪 Development Workflow

### Quality Validation

```bash
# Comprehensive validation (matches CI/CD)
./scripts/enhanced-local-validation.sh

# Quick validation (skip E2E tests)
./scripts/enhanced-local-validation.sh --skip-e2e

# Tests only
cd backend && pytest --cov=. --cov-fail-under=50
cd frontend && npm test -- --coverage
```

### Pre-commit Workflow

```bash
# Install pre-commit hooks
pip install pre-commit && pre-commit install

# Run all quality checks
pre-commit run --all-files
```

---

## ☁️ Production Deployment

### Azure Infrastructure Setup

```bash
# Configure secrets and deploy infrastructure
./scripts/setup-production-secrets.sh
cd infrastructure/bicep && ./deploy.sh

# Automatic deployment triggers on push to main
git push origin main
```

### Cost-Optimized Dual Resource Group Architecture

- **Monthly Cost:** ~$43/month (Basic App Service + PostgreSQL + Key Vault)
- **Pause Mode:** ~$30/month (delete compute resources, keep data)
- **Single Environment:** Direct production deployment for cost efficiency
- **Single Region:** Central US for cost optimization
- **Scalable Design:** Pay-as-you-grow with tier-based usage limits

---

## 📋 Project Structure

```
vigor/
├── backend/              # FastAPI application (Clean Architecture)
│   ├── api/             # REST API endpoints and schemas
│   ├── core/            # Business logic and LLM orchestration
│   ├── database/        # Models and repositories
│   └── infrastructure/  # External service adapters
├── frontend/            # React TypeScript application
│   ├── src/components/  # Reusable UI components
│   ├── src/pages/       # Route-level components
│   ├── src/services/    # API clients and external services
│   └── src/stores/      # Zustand state management
├── infrastructure/      # Azure Bicep IaC templates
├── scripts/            # Development and deployment automation
└── docs/               # Comprehensive project documentation
```

---

## 🎯 AI Provider Configuration

### Supported Providers

- **OpenAI GPT:** Premium AI coaching experience
- **Google Gemini:** Cost-effective alternative with competitive performance
- **Perplexity:** Research-focused AI for science-based advice
- **Fallback Mode:** Basic functionality without AI for cost-sensitive deployments

### Environment Variables

```bash
# Required
DATABASE_URL=postgresql://user:pass@host:5432/vigor
SECRET_KEY=your-jwt-signing-key-minimum-32-characters

# AI Provider (choose one)
LLM_PROVIDER=openai|gemini|perplexity|fallback
OPENAI_API_KEY=sk-...  # If using OpenAI
```

---

## 📊 Current Status

### Quality Metrics

- **Backend Test Coverage:** 50%+ (Target: 80%)
- **Frontend Test Coverage:** 31%+ (Target: 80%)
- **Test Pass Rate:** 82.9% (480/589 tests passing)
- **Security:** Comprehensive authentication, rate limiting, input validation

### Architecture Decisions

All major decisions are documented in `docs/adr/` with rationale and impact analysis. See `docs/metadata.md` for complete project roadmap and current sprint progress.

---

## 🤝 Contributing

1. Review `docs/CONTRIBUTING.md` for development guidelines
2. Run local validation before commits: `./scripts/enhanced-local-validation.sh`
3. All PRs require passing quality gates (coverage, linting, security)
4. Follow clean architecture principles and maintain test coverage

### Key Development Scripts

- **Enhanced Local Validation:** `./scripts/enhanced-local-validation.sh`
- **Health Check:** `./scripts/health-check.sh`
- **E2E Testing:** `./scripts/test-e2e-local.sh`
- **Workflow Validation:** `./scripts/validate-workflows.sh`

---

## 📚 Documentation

- **Complete Documentation:** `docs/`
- **API Documentation:** http://localhost:8000/docs (when backend running)
- **Architecture Decisions:** `docs/adr/`
- **User Experience Guide:** `docs/User_Experience.md`
- **Project Roadmap:** `docs/metadata.md`

---

## 📄 License

This project is licensed under the AGPL v3 License - see the [LICENSE](LICENSE) file for details.

---

**🚀 Ready to transform your fitness journey? Get started with Vigor today!**

---

## 🧪 Testing & Validation

### Comprehensive Testing

```bash
# Run modernization test suite
./scripts/test-modernization.sh

# Legacy backend tests
cd backend && source venv/bin/activate && pytest -v

# Frontend tests
cd frontend && npm test

# E2E tests
cd frontend && npm run test:e2e
```

### Quality Validation

```bash
# Full validation (matches CI/CD pipeline)
./scripts/enhanced-local-validation.sh

# Backend formatting
cd backend && source venv/bin/activate && black . && isort .

# Frontend linting
cd frontend && npm run lint:fix
```

---

## ☁️ Production Deployment

### Azure Infrastructure Deployment

**Modernized Infrastructure (Recommended)**

```bash
# Deploy unified resource group architecture
cd infrastructure/bicep
az deployment group create \
  --resource-group vigor-rg \
  --template-file main-modernized.bicep \
  --parameters @parameters-modernized.bicepparam
```

**Legacy Infrastructure**

```bash
# Deploy dual resource group architecture (legacy)
cd infrastructure/bicep
./deploy.sh  # Uses original main.bicep
```

### Azure Functions Deployment

```bash
# Deploy modernized backend
cd functions-modernized
func azure functionapp publish vigor-backend --python
```

### Environment Configuration

**Required Secrets (Azure Key Vault)**

```bash
# Core secrets
az keyvault secret set --vault-name vigor-kv-* --name "cosmos-connection-string" --value "AccountEndpoint=..."
az keyvault secret set --vault-name vigor-kv-* --name "gemini-api-key" --value "your-gemini-api-key"
```

**Frontend Environment**

```bash
# Create frontend/.env.local
VITE_AZURE_AD_CLIENT_ID=be183263-80c3-4191-bc84-2ee3c618cbcd
VITE_AZURE_AD_TENANT_ID=common
VITE_API_BASE_URL=https://vigor-backend-*.azurewebsites.net/api
```

---

## � Cost Optimization

### Infrastructure Costs (Monthly Estimates)

| Component | Modernized                     | Legacy             | Savings    |
| --------- | ------------------------------ | ------------------ | ---------- |
| Compute   | Azure Functions (~$5-15)       | App Service (~$55) | 70-85%     |
| Database  | Cosmos DB Serverless (~$20-25) | PostgreSQL (~$30)  | 15-35%     |
| Storage   | Function Storage (~$1-2)       | App Service (~$5)  | 60-80%     |
| **Total** | **~$30-50/month**              | **~$100/month**    | **40-70%** |

### Key Cost Benefits

- **Consumption-based pricing**: Pay only for actual usage
- **Automatic scaling**: Scale to zero when inactive
- **Single resource group**: Simplified management and billing
- **Serverless database**: Cosmos DB auto-pause during low usage

---

## � Project Structure

```
vigor/
├── backend/                    # Legacy FastAPI application (maintained)
│   ├── api/                   # REST endpoints and schemas
│   ├── core/                  # Business logic and domain models
│   ├── database/              # PostgreSQL models and repositories
│   └── infrastructure/        # External service integrations
├── functions-modernized/       # Azure Functions application (active)
│   ├── shared/                # Common utilities and models
│   ├── function_app.py        # Main functions entry point
│   └── requirements.txt       # Minimal Python dependencies
├── frontend/                   # React TypeScript application
│   ├── src/components/        # Reusable UI components
│   ├── src/pages/             # Route-level page components
│   ├── src/services/          # API clients and external services
│   └── src/config/            # MSAL and app configuration
├── infrastructure/             # Azure Bicep Infrastructure-as-Code
│   └── bicep/
│       ├── main-modernized.bicep      # Unified resource group template
│       └── main.bicep                 # Legacy dual resource group template
├── scripts/                    # Development and deployment automation
└── docs/                      # Comprehensive project documentation
```

---

## 🔐 Authentication & Security

### Microsoft Entra ID Integration

- **Provider**: Microsoft Entra ID default tenant
- **Flow**: MSAL.js browser authentication with JWT tokens
- **User Identification**: Email-based user records in Cosmos DB
- **Automatic User Creation**: New users automatically created on first login

### Security Features

- JWT token validation with Microsoft JWKS endpoint
- Rate limiting on API endpoints
- HTTPS enforcement on all endpoints
- Azure Key Vault for secrets management
- Managed identity for resource access

---

## 🎯 AI Configuration

### Gemini Flash 2.5 Integration

The modernized architecture uses Google Gemini Flash 2.5 as the single AI provider for:

- Personalized workout generation
- Real-time coaching conversations
- Progress analysis and recommendations
- Exercise form guidance and safety tips

### Provider Configuration

```python
# Environment variables
GEMINI_API_KEY=your-api-key  # Stored in Azure Key Vault
LLM_PROVIDER=gemini         # Single provider configuration
```

### Legacy Multi-Provider Support (Backend)

The legacy FastAPI backend still supports multiple providers:

- OpenAI GPT-4 (premium option)
- Google Gemini Pro (cost-effective)
- Perplexity Pro (research-focused)
- Fallback mode (template-based, no API costs)

---

## 📈 Current Status

### Implementation Progress

- **Infrastructure**: 100% deployed and operational ✅
- **Authentication**: 100% implemented with Microsoft Entra ID ✅
- **Frontend**: 100% modernized with MSAL.js integration ✅
- **Backend Migration**: 95% complete (minor Function App runtime issue) 🔧
- **Cost Optimization**: 40-70% reduction achieved ✅

### Known Issues

- **Function App Runtime**: FC1 Flex Consumption plan compatibility issue
- **Impact**: APIs not accessible, frontend authentication works independently
- **Resolution**: Consider Y1 standard Consumption plan or FC1 optimization

### Quality Metrics

- **Test Coverage**: Backend 50%+, Frontend 31%+ (improving)
- **Architecture**: Clean/Hexagonal design with clear separation of concerns
- **Security**: Comprehensive authentication, rate limiting, secrets management

---

## 🤝 Contributing

### Development Workflow

1. Fork the repository and create a feature branch
2. Run local validation: `./scripts/test-modernization.sh`
3. Follow clean architecture principles and maintain test coverage
4. Submit PR with clear description and test coverage

### Key Development Scripts

- **Modernization Testing**: `./scripts/test-modernization.sh`
- **Health Check**: `./scripts/health-check.sh`
- **Local Validation**: `./scripts/enhanced-local-validation.sh`
- **Backend Formatting**: `cd backend && black . && isort .`
- **Frontend Linting**: `cd frontend && npm run lint:fix`

### Documentation Requirements

- All architectural decisions documented in `docs/adr/`
- API changes reflected in OpenAPI schema
- User-facing changes updated in `docs/User_Experience.md`

---

## 📚 Documentation

| Document                       | Purpose                                      |
| ------------------------------ | -------------------------------------------- |
| `docs/PRD-Vigor.md`            | Product requirements and user scenarios      |
| `docs/Tech_Spec_Vigor.md`      | Technical architecture and implementation    |
| `docs/User_Experience.md`      | UX/UI design specifications                  |
| `docs/metadata.md`             | Project progress and architectural decisions |
| `docs/IMPLEMENTATION_GUIDE.md` | Complete deployment guide                    |
| `docs/PROJECT_COMPLETION.md`   | Modernization project summary                |

### API Documentation

- **Legacy Backend**: http://localhost:8000/docs (FastAPI OpenAPI)
- **Modernized Functions**: Function-specific documentation in code

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**🚀 Vigor: Modern serverless fitness platform with AI-powered personalization**

```bash
# Backend setup
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
LLM_PROVIDER=fallback python main.py  # http://localhost:8000

# Frontend setup (new terminal)
cd frontend && npm install && npm run dev  # http://localhost:5173
```

**🔑 Default Credentials:** `admin@vigor.com` / `admin123!`

### Docker Alternative

```bash
docker-compose up -d
# Access at http://localhost:5173
```

---

## 🧪 Development Workflow

### Quality Validation

```bash
# Comprehensive validation (matches CI/CD)
./scripts/enhanced-local-validation.sh

# Quick validation (skip E2E tests)
./scripts/enhanced-local-validation.sh --skip-e2e

# Tests only
cd backend && pytest --cov=. --cov-fail-under=50
cd frontend && npm test -- --coverage
```

### Pre-commit Workflow

```bash
# Install pre-commit hooks
pip install pre-commit && pre-commit install

# Run all quality checks
pre-commit run --all-files
```

---

## ☁️ Production Deployment

### Azure Infrastructure Setup

```bash
# Configure secrets and deploy infrastructure
./scripts/setup-production-secrets.sh
cd infrastructure/bicep && ./deploy.sh

# Automatic deployment triggers on push to main
git push origin main
```

### Cost-Optimized Dual Resource Group Architecture

- **Monthly Cost:** ~$43/month (Basic App Service + PostgreSQL + Key Vault)
- **Pause Mode:** ~$30/month (delete compute resources, keep data)
- **Single Environment:** Direct production deployment for cost efficiency
- **Single Region:** Central US for cost optimization
- **Scalable Design:** Pay-as-you-grow with tier-based usage limits

---

## 📋 Project Structure

```
vigor/
├── backend/              # FastAPI application (Clean Architecture)
│   ├── api/             # REST API endpoints and schemas
│   ├── core/            # Business logic and LLM orchestration
│   ├── database/        # Models and repositories
│   └── infrastructure/  # External service adapters
├── frontend/            # React TypeScript application
│   ├── src/components/  # Reusable UI components
│   ├── src/pages/       # Route-level components
│   ├── src/services/    # API clients and external services
│   └── src/stores/      # Zustand state management
├── infrastructure/      # Azure Bicep IaC templates
├── scripts/            # Development and deployment automation
└── docs/               # Comprehensive project documentation
```

---

## 🎯 AI Provider Configuration

### Supported Providers

- **OpenAI GPT:** Premium AI coaching experience
- **Google Gemini:** Cost-effective alternative with competitive performance
- **Perplexity:** Research-focused AI for science-based advice
- **Fallback Mode:** Basic functionality without AI for cost-sensitive deployments

### Environment Variables

```bash
# Required
DATABASE_URL=postgresql://user:pass@host:5432/vigor
SECRET_KEY=your-jwt-signing-key-minimum-32-characters

# AI Provider (choose one)
LLM_PROVIDER=openai|gemini|perplexity|fallback
OPENAI_API_KEY=sk-...  # If using OpenAI
```

---

## 📊 Current Status

### Quality Metrics

- **Backend Test Coverage:** 50%+ (Target: 80%)
- **Frontend Test Coverage:** 31%+ (Target: 80%)
- **Test Pass Rate:** 82.9% (480/589 tests passing)
- **Security:** Comprehensive authentication, rate limiting, input validation

### Architecture Decisions

All major decisions are documented in `docs/adr/` with rationale and impact analysis. See `docs/metadata.md` for complete project roadmap and current sprint progress.

---

## 🤝 Contributing

1. Review `docs/CONTRIBUTING.md` for development guidelines
2. Run local validation before commits: `./scripts/enhanced-local-validation.sh`
3. All PRs require passing quality gates (coverage, linting, security)
4. Follow clean architecture principles and maintain test coverage

### Key Development Scripts

- **Enhanced Local Validation:** `./scripts/enhanced-local-validation.sh`
- **Health Check:** `./scripts/health-check.sh`
- **E2E Testing:** `./scripts/test-e2e-local.sh`
- **Workflow Validation:** `./scripts/validate-workflows.sh`

---

## 📚 Documentation

- **Complete Documentation:** `docs/`
- **API Documentation:** http://localhost:8000/docs (when backend running)
- **Architecture Decisions:** `docs/adr/`
- **User Experience Guide:** `docs/User_Experience.md`
- **Project Roadmap:** `docs/metadata.md`

---

## 📄 License

This project is licensed under the AGPL v3 License - see the [LICENSE](LICENSE) file for details.

---

**🚀 Ready to transform your fitness journey? Get started with Vigor today!**
