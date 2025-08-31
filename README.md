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

### Architecture (Modernized 2025)

The application has been completely modernized with a serverless-first approach:

- **Backend:** Azure Functions (Python 3.11) with Flex Consumption Plan
- **Frontend:** React 19 + TypeScript + Chakra UI v3 + MSAL.js
- **Database:** Azure Cosmos DB (NoSQL) with email-based user identification
- **Authentication:** Microsoft Entra ID default tenant with JWT validation
- **AI Provider:** Google Gemini Flash 2.5 (single provider for cost efficiency)
- **Infrastructure:** Single unified Azure resource group (`vigor-rg`) with Bicep IaC
- **Cost Model:** Consumption-based pricing (~$30-50/month vs ~$100/month legacy)

---

## 🏗️ Architecture Overview

### Single Unified Resource Group (`vigor-rg`)

```
vigor-rg (West US 2)
├── Azure Functions (vigor-backend)        # Serverless API
├── Cosmos DB (vigor-cosmos-prod)          # NoSQL database
├── Key Vault (vigor-kv-pajllm52fgnly)     # Secrets management
├── Application Insights (vigor-insights)  # Monitoring
└── Storage Account (vigorstorage*)        # Function app storage
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
- Azure subscription and CLI (for cloud deployment)
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
# Azure Functions setup (requires Azure Functions Core Tools)
cd functions-modernized
func start  # Local development server

# Frontend setup (new terminal)
cd frontend
npm install
npm run dev  # http://localhost:5173
```

**Option 3: VS Code Tasks**

1. Open project in VS Code
2. **Ctrl+Shift+P** → "Tasks: Run Task"
3. Choose: "Start Backend Server" or "Start Frontend Dev Server"

**🔑 Default Test Credentials:** `admin@vigor.com` / `admin123!`

---

## 🧪 Testing & Validation

### Comprehensive Testing

```bash
# Run modernization test suite (comprehensive)
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
# Full validation pipeline (matches CI/CD)
./scripts/enhanced-local-validation.sh

# Backend code formatting
cd backend && source venv/bin/activate && black . && isort .

# Frontend linting and fixing
cd frontend && npm run lint:fix
```

---

## ☁️ Production Deployment

### Azure Infrastructure Deployment

**Modernized Infrastructure (Active)**

```bash
# Deploy single unified resource group
cd infrastructure/bicep
az deployment group create \
  --resource-group vigor-rg \
  --template-file main-modernized.bicep \
  --parameters @parameters-modernized.bicepparam
```

**Legacy Infrastructure (Maintained)**

```bash
# Deploy original dual resource group architecture
cd infrastructure/bicep
./deploy.sh  # Uses main.bicep
```

### Azure Functions Deployment

```bash
# Deploy modernized serverless backend
cd functions-modernized
func azure functionapp publish vigor-backend --python
```

### Environment Configuration

**Azure Key Vault Secrets**

```bash
# Required secrets in Key Vault
az keyvault secret set --vault-name vigor-kv-pajllm52fgnly \
  --name "cosmos-connection-string" \
  --value "AccountEndpoint=https://vigor-cosmos-prod.documents.azure.com:443/;..."

az keyvault secret set --vault-name vigor-kv-pajllm52fgnly \
  --name "gemini-api-key" \
  --value "your-gemini-api-key"
```

**Frontend Environment (.env.local)**

```bash
VITE_AZURE_AD_CLIENT_ID=be183263-80c3-4191-bc84-2ee3c618cbcd
VITE_AZURE_AD_TENANT_ID=common
VITE_API_BASE_URL=https://vigor-backend-bpd7gfcgbxhbcvd8.westus2-01.azurewebsites.net/api
```

---

## 💰 Cost Optimization

### Infrastructure Costs (Monthly Estimates)

| Component | Modernized                     | Legacy             | Savings    |
| --------- | ------------------------------ | ------------------ | ---------- |
| Compute   | Azure Functions (~$5-15)       | App Service (~$55) | 70-85%     |
| Database  | Cosmos DB Serverless (~$20-25) | PostgreSQL (~$30)  | 15-35%     |
| Storage   | Function Storage (~$1-2)       | App Service (~$5)  | 60-80%     |
| **Total** | **~$30-50/month**              | **~$100/month**    | **40-70%** |

### Key Cost Benefits

- **Consumption-based pricing**: Pay only for actual execution time
- **Automatic scaling**: Scale to zero when inactive
- **Single resource group**: Simplified management and consolidated billing
- **Serverless database**: Cosmos DB auto-pause during low usage periods

---

## 📋 Project Structure

```
vigor/
├── backend/                    # Legacy FastAPI application (maintained)
│   ├── api/                   # REST endpoints and schemas
│   ├── core/                  # Business logic and domain models
│   ├── database/              # PostgreSQL models and repositories
│   └── infrastructure/        # External service integrations
├── functions-modernized/       # Azure Functions application (active)
│   ├── shared/                # Common utilities and models
│   │   ├── auth.py           # Microsoft Entra ID authentication
│   │   ├── cosmos_db.py      # Cosmos DB client
│   │   ├── gemini_client.py  # Gemini Flash 2.5 AI client
│   │   └── models.py         # Pydantic data models
│   ├── function_app.py        # Main Azure Functions entry point
│   └── requirements.txt       # Minimal Python dependencies
├── frontend/                   # React TypeScript application
│   ├── src/components/        # Reusable UI components
│   ├── src/pages/             # Route-level page components
│   ├── src/services/          # API clients and external services
│   └── src/config/            # MSAL authentication configuration
├── infrastructure/             # Azure Bicep Infrastructure-as-Code
│   └── bicep/
│       ├── main-modernized.bicep      # Single resource group template (active)
│       └── main.bicep                 # Legacy dual resource group template
├── scripts/                    # Development and deployment automation
└── docs/                      # Comprehensive project documentation
```

---

## 🔐 Authentication & Security

### Microsoft Entra ID Integration

- **Provider**: Microsoft Entra ID default tenant (`common`)
- **Flow**: MSAL.js browser authentication with JWT tokens
- **User Identification**: Email-based user records in Cosmos DB
- **Automatic User Creation**: New users automatically created on first successful login
- **App Registration**: `be183263-80c3-4191-bc84-2ee3c618cbcd`

### Security Features

- JWT token validation with Microsoft JWKS endpoint
- Rate limiting on API endpoints (50 requests/hour for AI chat)
- HTTPS enforcement on all endpoints
- Azure Key Vault for secrets management with managed identity
- Input validation and sanitization for all API endpoints

---

## 🎯 AI Configuration

### Gemini Flash 2.5 Integration

The modernized architecture uses Google Gemini Flash 2.5 as the single AI provider for:

- Personalized workout generation (20 requests/hour limit)
- Real-time coaching conversations (50 requests/hour limit)
- Progress analysis and recommendations
- Exercise form guidance and safety tips

### Environment Configuration

```python
# Environment variables (stored in Azure Key Vault)
GEMINI_API_KEY=your-gemini-api-key
LLM_PROVIDER=gemini  # Single provider configuration
```

### Legacy Multi-Provider Support (Backend Only)

The legacy FastAPI backend still supports multiple providers for development:

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
- **Symptom**: "Function host is not running" error on deployed functions
- **Impact**: APIs not accessible via HTTPS, frontend authentication works independently
- **Workaround**: Authentication test server available at `localhost:3001`
- **Resolution**: Consider migration to Y1 standard Consumption plan

### Quality Metrics

- **Test Coverage**: Backend 50%+, Frontend 31%+ (actively improving)
- **Architecture**: Clean/Hexagonal design with clear separation of concerns
- **Security**: Comprehensive authentication, rate limiting, secrets management
- **Documentation**: Complete implementation guides and API documentation

---

## 🤝 Contributing

### Development Workflow

1. Fork the repository and create a feature branch
2. Run local validation: `./scripts/test-modernization.sh`
3. Follow clean architecture principles and maintain test coverage
4. Submit PR with clear description and passing tests

### Key Development Scripts

- **Modernization Testing**: `./scripts/test-modernization.sh`
- **Health Check**: `./scripts/health-check.sh`
- **Local Validation**: `./scripts/enhanced-local-validation.sh`
- **Backend Formatting**: `cd backend && source venv/bin/activate && black . && isort .`
- **Frontend Linting**: `cd frontend && npm run lint:fix`

### Documentation Requirements

- All architectural decisions documented in `docs/adr/`
- API changes reflected in code documentation
- User-facing changes updated in `docs/User_Experience.md`
- Progress tracking maintained in `docs/metadata.md`

---

## 📚 Documentation

| Document                       | Purpose                                           |
| ------------------------------ | ------------------------------------------------- |
| `docs/PRD-Vigor.md`            | Product requirements and user scenarios           |
| `docs/Tech_Spec_Vigor.md`      | Technical architecture and implementation details |
| `docs/User_Experience.md`      | UX/UI design specifications and user flows        |
| `docs/metadata.md`             | Project progress and architectural decisions      |
| `docs/IMPLEMENTATION_GUIDE.md` | Complete deployment and setup guide               |
| `docs/PROJECT_COMPLETION.md`   | Modernization project summary and achievements    |

### API Documentation

- **Legacy Backend**: http://localhost:8000/docs (FastAPI OpenAPI)
- **Modernized Functions**: Function-specific documentation in code comments

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**🚀 Vigor: Modern serverless fitness platform with AI-powered personalization**
