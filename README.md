# 🏋️‍♂️ Vigor - AI Fitness Platform

> **AI-powered fitness coaching with personalized workout generation and progress tracking.**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![React 19](https://img.shields.io/badge/react-19-blue.svg)](https://reactjs.org/)
[![Azure Functions](https://img.shields.io/badge/Azure%20Functions-Serverless-green.svg)](https://azure.microsoft.com/en-us/services/functions/)
[![Cosmos DB](https://img.shields.io/badge/Cosmos%20DB-NoSQL-blue.svg)](https://azure.microsoft.com/en-us/services/cosmos-db/)

---

## ✨ Overview

**Vigor** is an AI-powered fitness platform built with serverless architecture. The application provides personalized workout generation, AI coaching conversations, and comprehensive progress tracking.

### Key Features

- **🤖 AI Fitness Coach** - Conversational coaching powered by Google Gemini Flash 2.5
- **📋 Personalized Workouts** - AI-generated workout plans based on user goals and available equipment
- **📊 Progress Tracking** - Comprehensive analytics with workout logs and performance metrics
- **💬 Interactive Coaching** - Real-time chat interface for fitness guidance and form tips
- **📱 Mobile-First Design** - Responsive interface optimized for mobile devices
- **🔐 Secure Authentication** - Microsoft Entra ID integration with email-based user management

### Tech Stack

- **Backend:** Azure Functions (Python 3.11)
- **Frontend:** React 19 + TypeScript + Chakra UI v3 + MSAL.js
- **Database:** Azure Cosmos DB (NoSQL)
- **Authentication:** Microsoft Entra ID with JWT validation
- **AI Provider:** Google Gemini Flash 2.5
- **Infrastructure:** Azure with Bicep IaC

---

## 🏗️ Architecture Overview

### Azure Resource Group

```
vigor-rg (West US 2)
├── Azure Functions (vigor-backend)        # Serverless API
├── Cosmos DB (vigor-cosmos-prod)          # NoSQL database
├── Key Vault (vigor-kv-*)                 # Secrets management
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

**Backend + Frontend**

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

**VS Code Tasks**

1. Open project in VS Code
2. **Ctrl+Shift+P** → "Tasks: Run Task"
3. Choose: "Start Backend Server" or "Start Frontend Dev Server"

---

## 🧪 Testing

```bash
# Backend tests
cd backend && source venv/bin/activate && pytest -v

# Frontend tests
cd frontend && npm test

# E2E tests
cd frontend && npm run test:e2e
```

### Code Quality

```bash
# Backend formatting
cd backend && source venv/bin/activate && black . && isort .

# Frontend linting
cd frontend && npm run lint:fix
```

---

## ☁️ Production Deployment

### Azure Infrastructure

```bash
cd infrastructure/bicep
az deployment group create \
  --resource-group vigor-rg \
  --template-file main-modernized.bicep \
  --parameters @parameters-modernized.bicepparam
```

### Azure Functions

```bash
cd functions-modernized
func azure functionapp publish vigor-backend --python
```

### Environment Configuration

**Azure Key Vault Secrets**

```bash
az keyvault secret set --vault-name <your-keyvault> \
  --name "cosmos-connection-string" \
  --value "AccountEndpoint=https://..."

az keyvault secret set --vault-name <your-keyvault> \
  --name "gemini-api-key" \
  --value "your-gemini-api-key"
```

**Frontend Environment (.env.local)**

```bash
VITE_AZURE_AD_CLIENT_ID=<your-client-id>
VITE_AZURE_AD_TENANT_ID=common
VITE_API_BASE_URL=https://<your-function-app>.azurewebsites.net/api
```

---

## 📋 Project Structure

```
vigor/
├── backend/                    # FastAPI application
│   ├── api/                   # REST endpoints and schemas
│   ├── core/                  # Business logic and domain models
│   ├── database/              # Database models and repositories
│   └── infrastructure/        # External service integrations
├── functions-modernized/       # Azure Functions application
│   ├── shared/                # Common utilities and models
│   ├── function_app.py        # Main Azure Functions entry point
│   └── requirements.txt       # Python dependencies
├── frontend/                   # React TypeScript application
│   ├── src/components/        # Reusable UI components
│   ├── src/pages/             # Route-level page components
│   ├── src/services/          # API clients and external services
│   └── src/config/            # Authentication configuration
├── infrastructure/             # Azure Bicep Infrastructure-as-Code
├── scripts/                    # Development and deployment automation
└── docs/                      # Project documentation
```

---

## 🔐 Authentication & Security

### Microsoft Entra ID Integration

- **Provider**: Microsoft Entra ID default tenant (`common`)
- **Flow**: MSAL.js browser authentication with JWT tokens
- **User Identification**: Email-based user records in Cosmos DB
- **Automatic User Creation**: New users created on first successful login

### Security Features

- JWT token validation with Microsoft JWKS endpoint
- Rate limiting on API endpoints
- HTTPS enforcement on all endpoints
- Azure Key Vault for secrets management
- Input validation and sanitization

---

## 🎯 AI Configuration

### Gemini Flash 2.5

The platform uses Google Gemini Flash 2.5 for:

- Personalized workout generation
- Real-time coaching conversations
- Progress analysis and recommendations
- Exercise form guidance and safety tips

```bash
# Environment variable (stored in Azure Key Vault)
GEMINI_API_KEY=your-gemini-api-key
```

---

## 🤝 Contributing

1. Fork the repository and create a feature branch
2. Run tests: `cd backend && pytest -v` and `cd frontend && npm test`
3. Follow clean architecture principles and maintain test coverage
4. Submit PR with clear description and passing tests

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for detailed guidelines.

---

## 📚 Documentation

| Document                  | Purpose                                           |
| ------------------------- | ------------------------------------------------- |
| `docs/PRD-Vigor.md`       | Product requirements and user scenarios           |
| `docs/Tech_Spec_Vigor.md` | Technical architecture and implementation details |
| `docs/User_Experience.md` | UX/UI design specifications and user flows        |
| `docs/metadata.md`        | Project progress and architectural decisions      |
| `docs/CONTRIBUTING.md`    | Contribution guidelines and development workflow  |

---

## 📄 License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

---

**🚀 Vigor: AI-powered fitness platform with personalized coaching**
