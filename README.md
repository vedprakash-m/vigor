# 🏋️‍♂️ Vigor - AI Fitness Platform

> **AI-powered fitness coaching with personalized workout generation and progress tracking.**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](LICENSE)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![React 19](https://img.shields.io/badge/react-19-blue.svg)](https://reactjs.org/)
[![Azure Functions](https://img.shields.io/badge/Azure%20Functions-Serverless-green.svg)](https://azure.microsoft.com/en-us/services/functions/)
[![Cosmos DB](https://img.shields.io/badge/Cosmos%20DB-NoSQL-blue.svg)](https://azure.microsoft.com/en-us/services/cosmos-db/)

---

## ✨ Overview

**Vigor** is an AI-powered fitness platform built with serverless architecture on Azure. The application provides personalized workout generation, AI coaching conversations, and comprehensive progress tracking.

### Key Features

- **🤖 AI Fitness Coach** - Conversational coaching powered by OpenAI gpt-5-mini
- **📋 Personalized Workouts** - AI-generated workout plans based on user goals and available equipment
- **📊 Progress Tracking** - Comprehensive analytics with workout logs and performance metrics
- **💬 Interactive Coaching** - Real-time chat interface for fitness guidance and form tips
- **📱 Mobile-First Design** - Responsive interface optimized for mobile devices
- **🔐 Secure Authentication** - Microsoft Entra ID integration with automatic user creation

### Tech Stack

| Layer        | Technology                                          |
| ------------ | --------------------------------------------------- |
| **Frontend** | React 19, TypeScript 5, Vite, Chakra UI v3, MSAL.js |
| **Backend**  | Azure Functions (Python 3.11, Flex Consumption)     |
| **Database** | Azure Cosmos DB Serverless                          |
| **AI**       | OpenAI gpt-5-mini                                   |
| **Auth**     | Microsoft Entra ID (default tenant)                 |
| **Hosting**  | Azure Static Web Apps + Azure Functions             |
| **IaC**      | Bicep                                               |

---

## 🏗️ Architecture

### Single Resource Group (vigor-rg, West US 2)

```
vigor-rg (West US 2)
├── vigor-functions          # Azure Functions (Flex Consumption)
├── vigor-frontend           # Static Web App
├── vigor-cosmos             # Cosmos DB Serverless
├── vigor-kv-*               # Key Vault (secrets)
├── vigor-ai                 # Application Insights
├── vigor-la                 # Log Analytics
└── vigorsa*                 # Storage Account
```

### Database Schema (Cosmos DB)

| Container           | Partition Key | Purpose                       |
| ------------------- | ------------- | ----------------------------- |
| `users`             | `/userId`     | User profiles and preferences |
| `workouts`          | `/userId`     | AI-generated workout plans    |
| `workout_logs`      | `/userId`     | Exercise completion tracking  |
| `ai_coach_messages` | `/userId`     | Chat history (30-day TTL)     |

---

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Node.js 18+
- Azure Functions Core Tools v4
- Azure CLI (for deployment)

### Local Development

**1. Backend (Azure Functions)**

```bash
cd functions-modernized
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

export OPENAI_API_KEY="your-openai-api-key"
func start  # http://localhost:7071
```

**2. Frontend**

```bash
cd frontend
npm install
echo "VITE_API_URL=http://localhost:7071" > .env.local
npm run dev  # http://localhost:5173
```

---

## 🔌 API Endpoints

| Method     | Endpoint                 | Description                |
| ---------- | ------------------------ | -------------------------- |
| GET        | `/api/auth/me`           | Get current user profile   |
| GET/PUT    | `/api/users/profile`     | Get or update user profile |
| POST       | `/api/workouts/generate` | Generate AI workout plan   |
| GET        | `/api/workouts`          | List user's workouts       |
| GET        | `/api/workouts/history`  | Get workout logs history   |
| POST       | `/api/coach/chat`        | Chat with AI coach         |
| GET/DELETE | `/api/coach/history`     | Get or clear chat history  |
| GET        | `/api/health`            | Health check               |

---

## 🧪 Testing

```bash
# Backend tests
cd functions-modernized && pytest -v

# Frontend tests
cd frontend && npm test

# E2E tests
cd frontend && npm run test:e2e
```

---

## ☁️ Deployment

### Infrastructure (Bicep)

```bash
cd infrastructure/bicep
az login
az group create --name vigor-rg --location "West US 2"
./deploy-modernized.sh
```

### Deploy Functions

```bash
cd functions-modernized
func azure functionapp publish vigor-functions --python
```

---

## 📁 Project Structure

```
vigor/
├── frontend/                    # React 19 + TypeScript SPA
│   ├── src/
│   │   ├── components/         # LLMStatus, Layout, ProtectedRoute
│   │   ├── pages/              # WorkoutPage, CoachPage, DashboardPage
│   │   ├── services/           # Unified API client (api.ts)
│   │   ├── contexts/           # VedAuthContext (MSAL)
│   │   └── config/             # authConfig.ts
│   └── package.json
│
├── functions-modernized/        # Azure Functions Python backend
│   ├── function_app.py         # All HTTP endpoints
│   ├── shared/
│   │   ├── auth.py             # Entra ID JWT validation
│   │   ├── config.py           # Environment settings
│   │   ├── cosmos_db.py        # Database operations
│   │   ├── openai_client.py    # AI integration (gpt-5-mini)
│   │   ├── models.py           # Pydantic models
│   │   └── rate_limiter.py     # Rate limiting
│   └── requirements.txt
│
├── infrastructure/bicep/        # Azure Bicep IaC templates
├── scripts/                     # Deployment scripts
├── docs/                        # Documentation
└── .archive/                    # Archived legacy code
```

---

## 💰 Cost Estimates

| Resource        | Tier             | Monthly Cost     |
| --------------- | ---------------- | ---------------- |
| Static Web App  | Free             | $0               |
| Azure Functions | Flex Consumption | $5-15            |
| Cosmos DB       | Serverless       | $5-20            |
| Key Vault       | Standard         | ~$1              |
| OpenAI API      | Pay-per-token    | $5-15            |
| **Total**       |                  | **$16-51/month** |

_Estimated for 100 daily active users with moderate usage_

---

## 🔐 Authentication

- **Provider**: Microsoft Entra ID (default tenant `common`)
- **Flow**: MSAL.js browser authentication with JWT tokens
- **User Creation**: Automatic on first login

---

## 📄 License

GNU Affero General Public License v3.0 - see [LICENSE](LICENSE).

---

**🚀 Vigor: AI-powered fitness platform with personalized coaching**
