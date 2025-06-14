# 🏋️‍♂️ Vigor - AI-Powered Fitness Coaching Platform

> **Transform your fitness journey with personalized AI coaching, smart workout generation, and cost-optimized LLM integration.**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![React 18](https://img.shields.io/badge/react-18+-blue.svg)](https://reactjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com/)

## 🌟 Why Choose Vigor?

**Vigor** is a next-generation fitness platform that democratizes access to personalized AI fitness coaching. Unlike expensive personal trainers or generic workout apps, Vigor provides:

- **💰 Cost-Effective AI Coaching**: 70-90% cheaper than traditional personal training
- **🤖 Multi-LLM Support**: Choose from OpenAI, Google Gemini, or Perplexity based on your budget
- **📱 Mobile-First Design**: Responsive, PWA-ready interface for seamless mobile experience
- **🎯 Personalized Workouts**: AI-generated plans tailored to your goals, equipment, and fitness level
- **📊 Progress Tracking**: Smart analytics to monitor your fitness journey
- **🔒 Privacy-First**: Your data stays secure with enterprise-grade authentication

---

## 🚀 Key Features

### 🤖 AI-Powered Coaching

- **Interactive Chat**: Real-time conversations with your AI fitness coach
- **Smart Workout Generation**: Personalized workout plans based on your profile
- **Form Analysis**: Get feedback on your exercise technique (coming soon)
- **Progress Insights**: AI-driven analysis of your fitness journey

### 💰 User Tier System

- **Free Tier**: 100 AI requests/month with basic features
- **Premium Tier**: 1,000 AI requests/month + advanced coaching
- **Unlimited Tier**: Unlimited AI access + priority support
- **Usage Tracking**: Real-time monitoring of your AI usage and budget
- **Smart Upgrades**: Seamless tier upgrades when you need more capacity

### 💡 Flexible LLM Integration

- **Multi-Provider Support**: OpenAI, Google Gemini, Perplexity
- **Cost Optimization**: Switch providers to optimize for budget vs. performance
- **Graceful Fallback**: Works even without AI providers configured
- **Real-time Provider Status**: Monitor which AI service is active

### 📱 Modern User Experience

- **Responsive Design**: Optimized for mobile, tablet, and desktop
- **Progressive Web App**: Install directly on your device
- **Dark/Light Mode**: Comfortable viewing in any environment
- **Offline Support**: Core features work without internet (coming soon)

### 🔧 Developer-Friendly

- **Clean Architecture**: Modular, scalable codebase
- **Comprehensive API**: RESTful endpoints with OpenAPI documentation
- **Type Safety**: Full TypeScript support
- **Testing Ready**: Structure prepared for unit and integration tests

---

## 🏗️ Technology Stack

### Backend

- **Framework**: FastAPI (Python 3.9+)
- **Database**: SQLite (dev) / PostgreSQL (prod)
- **Authentication**: JWT with refresh tokens
- **AI Integration**: Multi-provider LLM abstraction
- **ORM**: SQLAlchemy with Alembic migrations
- **Validation**: Pydantic models

### Frontend

- **Framework**: React 18 + TypeScript
- **UI Library**: Chakra UI v3
- **State Management**: React Context + Hooks
- **Build Tool**: Vite
- **Styling**: Emotion (CSS-in-JS)
- **PWA**: Service Worker ready

### AI Providers

- **OpenAI**: GPT-3.5-turbo, GPT-4
- **Google Gemini**: Gemini-2.5-flash, Gemini-2.5-pro
- **Perplexity**: Llama-3.1-sonar models
- **Fallback**: Built-in responses for demo mode

---

## 🚀 Quick Start

### Prerequisites

- **Python 3.9+**
- **Node.js 18+**
- **Git**

### 1. Clone Repository

```bash
git clone https://github.com/vedprakash-m/vigor.git
cd vigor
```

### 2. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment (optional - app works without API keys)
export LLM_PROVIDER=gemini
export GEMINI_API_KEY=your-api-key-here

# Run database migrations
alembic upgrade head

# Start the server
python main.py
```

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

### 4. Access the Application

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8001
- **API Documentation**: http://localhost:8001/docs

#### Default Admin User

- **Email**: admin@vigor.com
- **Password**: admin123!

---

## 💰 Cost Optimization Guide

### LLM Provider Comparison

| Provider          | Cost (per 1M tokens) | Free Tier    | Best For                   |
| ----------------- | -------------------- | ------------ | -------------------------- |
| **Google Gemini** | $0.075 - $0.30       | ✅ Available | Development, Budget        |
| **Perplexity**    | $0.20 - $0.20        | ❌ Paid      | Real-time data, Production |
| **OpenAI**        | $0.50 - $1.50        | ❌ Paid      | Advanced reasoning         |

### Recommended Setup

1. **Development**: Use Gemini with free tier
2. **Production**: Switch to Perplexity for cost-effectiveness
3. **Premium Features**: Upgrade to OpenAI for advanced capabilities

### Switch Providers Instantly

```bash
# Use Google Gemini (recommended for cost)
export LLM_PROVIDER=gemini
export GEMINI_API_KEY=your-key

# Use Perplexity (good value)
export LLM_PROVIDER=perplexity
export PERPLEXITY_API_KEY=your-key

# Use OpenAI (premium)
export LLM_PROVIDER=openai
export OPENAI_API_KEY=your-key
```

---

## 📚 API Documentation

### Core Endpoints

#### Authentication

- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `POST /auth/refresh` - Refresh access token

#### AI Services

- `POST /ai/chat` - Chat with AI coach
- `POST /ai/workout-plan` - Generate workout plan
- `GET /ai/provider-status` - Check active AI provider

#### User Management

- `GET /users/me` - Get current user profile
- `PUT /users/me` - Update user profile

#### Tier Management

- `GET /tiers` - Get available tiers and current user tier
- `POST /tiers/upgrade` - Upgrade user tier
- `GET /tiers/analytics` - Get usage analytics

### Full API Documentation

Visit http://localhost:8001/docs for interactive API documentation.

---

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend │    │  FastAPI Backend │    │  AI Providers   │
│                 │    │                 │    │                 │
│ • Chakra UI     │◄───┤ • JWT Auth      │◄───┤ • OpenAI        │
│ • TypeScript    │    │ • User Tiers    │    │ • Gemini        │
│ • PWA Ready     │    │ • Usage Tracking│    │ • Perplexity    │
│ • Mobile-First  │    │ • LLM Abstraction│    │ • Fallback      │
│ • Tier UI       │    │ • RESTful API   │    │ • Cost Tracking │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Key Design Principles

- **Separation of Concerns**: Clear boundaries between UI, business logic, and AI services
- **Provider Agnostic**: LLM abstraction allows seamless provider switching
- **Progressive Enhancement**: Core features work offline, AI enhances the experience
- **Cost-Conscious**: Built-in cost optimization and monitoring

---

## 🚀 Production Deployment

> **Status**: ✅ **Production-Ready Infrastructure** with Azure Bicep deployment

### **Quick Deploy to Azure**

```bash
# 1. Clone and setup
git clone https://github.com/vedprakash-m/vigor.git
cd vigor

# 2. Set up GitHub secrets for CI/CD
./scripts/setup-production-secrets.sh

# 3. Deploy infrastructure to Azure (West US 2 optimized)
cd infrastructure/bicep && ./deploy-west-us-2.sh

# 4. Push to trigger application deployment
git push origin main
```

### **Infrastructure Features**

- **🏗️ Azure Bicep**: Modern Infrastructure as Code (migrated from Terraform)
- **🔐 OIDC Authentication**: Secure GitHub Actions deployment without client secrets
- **🌍 West US 2 Optimized**: <20ms latency for West Coast users
- **💰 Cost Optimized**: ~$150-180/month for production workload
- **📊 Full Monitoring**: Application Insights + Log Analytics
- **🔒 Enterprise Security**: Azure Key Vault + managed identities

### **Azure Resources Deployed**

| Resource                 | SKU       | Purpose                    |
| ------------------------ | --------- | -------------------------- |
| **App Service**          | B1 Basic  | Backend API (FastAPI)      |
| **Static Web App**       | Standard  | Frontend (React + Vite)    |
| **PostgreSQL**           | B1ms      | Database with 10GB storage |
| **Redis Cache**          | Basic 1GB | Session management         |
| **Container Registry**   | Basic     | Docker image storage       |
| **Key Vault**            | Standard  | Secure secret management   |
| **Application Insights** | -         | Performance monitoring     |

### **Environment Setup**

#### Required Secrets (via GitHub or Azure CLI)

```bash
# Database
POSTGRES_ADMIN_PASSWORD=your-secure-db-password

# Application Security
SECRET_KEY=your-jwt-signing-key-32chars-min
ADMIN_EMAIL=admin@your-domain.com

# Azure Authentication (auto-configured)
AZURE_CLIENT_ID=42aae4cc-5dd0-4469-9f10-87e45dc45088
AZURE_TENANT_ID=80fe68b7-105c-4fb9-ab03-c9a818e35848
AZURE_SUBSCRIPTION_ID=8c48242c-a20e-448a-ac0f-be75ac5ebad0
```

#### Optional (AI Features)

```bash
# AI Providers (cost-optimized order)
GEMINI_API_KEY=your-gemini-key       # Primary (cost-effective)
PERPLEXITY_API_KEY=your-perplexity-key  # Secondary (balanced)
OPENAI_API_KEY=your-openai-key       # Premium (advanced features)
```

---

## 🧪 Testing

### Backend Tests

```bash
cd backend
pytest tests/ -v
```

### Frontend Tests

```bash
cd frontend
npm test
```

### E2E Tests

```bash
npm run test:e2e
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- 🐛 **Bug reports and feature requests**
- 💻 **Code contributions and pull requests**
- 📝 **Documentation improvements**
- 🧪 **Testing and quality assurance**

**Contributors must agree that their contributions will be licensed under AGPLv3.**

### Community

- **GitHub Issues**: [Report bugs or request features](https://github.com/vedprakash-m/vigor/issues)
- **GitHub Discussions**: [Ask questions and share ideas](https://github.com/vedprakash-m/vigor/discussions)
- **Documentation**: [Read the docs](https://github.com/vedprakash-m/vigor/wiki)

---

## 📖 Additional Resources

### Documentation

- [LLM Provider Setup Guide](backend/LLM_SETUP.md)
- [API Reference](http://localhost:8000/docs)
- [Contributing Guide](CONTRIBUTING.md)

### Getting API Keys

- [Google Gemini (Free Tier)](https://makersuite.google.com/app/apikey)
- [Perplexity API](https://docs.perplexity.ai/)
- [OpenAI Platform](https://platform.openai.com/api-keys)

### Technical Documentation

- [Database Schema](backend/database/models.py) - Complete database models with tier system
- [Usage Tracking Service](backend/api/services/usage_tracking.py) - AI usage monitoring
- [Tier Management API](backend/api/routes/tiers.py) - Tier upgrade and analytics endpoints
- [Migration Files](backend/alembic/versions/) - Database migration history

### Community

- [Discord Community](https://discord.gg/vigor-fitness) (coming soon)
- [GitHub Discussions](https://github.com/vedprakash-m/vigor/discussions)
- [Issue Tracker](https://github.com/vedprakash-m/vigor/issues)

---

## 📄 License & Contributing

### License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPLv3)**.

**What this means:**

- ✅ **Free to use, modify, and distribute**
- ✅ **Commercial use allowed**
- ⚠️ **Source code must be disclosed when distributed**
- ⚠️ **Network use requires source disclosure** (AGPLv3 specific requirement)
- ⚠️ **Derivative works must use the same license**

**Important:** If you run Vigor on a server and provide access to users over a network, you must make the source code available to those users. This includes any modifications you make.

For the full license text, see the [LICENSE](LICENSE) file.

### Alternative Licensing

For commercial entities that prefer not to comply with AGPLv3 requirements, alternative commercial licensing may be available. Please contact the copyright holder for more information.

### Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- 🐛 **Bug reports and feature requests**
- 💻 **Code contributions and pull requests**
- 📝 **Documentation improvements**
- 🧪 **Testing and quality assurance**

**Contributors must agree that their contributions will be licensed under AGPLv3.**

### Community

- **GitHub Issues**: [Report bugs or request features](https://github.com/vedprakash-m/vigor/issues)
- **GitHub Discussions**: [Ask questions and share ideas](https://github.com/vedprakash-m/vigor/discussions)
- **Documentation**: [Read the docs](https://github.com/vedprakash-m/vigor/wiki)

---

## 🙏 Acknowledgments

- **OpenAI, Google, and Perplexity** for providing excellent AI APIs
- **FastAPI** and **React** communities for amazing frameworks
- **Chakra UI** for the beautiful component library
- **Open source community** for inspiration and tools

---

**Copyright (C) 2025 Vedprakash Mishra**

_This project is licensed under AGPLv3. See [LICENSE](LICENSE) and [NOTICE](NOTICE) files for details._

---

## 📊 Project Status

**Current Version**: v1.1.0
**Status**: ✅ **Production-Ready** - Infrastructure deployed and optimized
**Next Release**: v1.2.0 - Enhanced UI features and performance optimizations

### Recent Achievements ✅

**Infrastructure Modernization (December 2024)**

- **✅ Azure Bicep Migration**: Replaced Terraform with modern Azure-native IaC
- **✅ OIDC Authentication**: Secure GitHub Actions deployment without client secrets
- **✅ West US 2 Optimization**: <20ms latency for West Coast users
- **✅ Cost Optimization**: Eliminated Terraform state storage (~$5/month savings)
- **✅ CI/CD Pipeline**: Fully automated deployment with enhanced error handling

**Application Features (Completed)**

- **✅ Backend Infrastructure**: FastAPI server with JWT authentication
- **✅ User Tier System**: Free/Premium/Unlimited with usage tracking
- **✅ Multi-LLM Support**: OpenAI, Gemini, Perplexity with cost optimization
- **✅ Database System**: PostgreSQL with Alembic migrations
- **✅ Admin Dashboard**: User management and system administration
- **✅ Security**: Azure Key Vault integration and managed identities

### Current Status 🔄

**Ready for Production**

- ✅ Infrastructure: Fully deployed and tested on Azure
- ✅ CI/CD Pipeline: Automated deployment via GitHub Actions
- ✅ Security: Enterprise-grade authentication and secret management
- ✅ Monitoring: Application Insights with custom dashboards
- ✅ Cost Management: Optimized resource tiers and quota-aware deployment

**Development Focus**

- 🔄 Frontend tier management UI completion
- 🔄 Performance optimization and caching
- 🔄 Enhanced mobile responsiveness
- 🔄 User onboarding flow improvements

### Infrastructure Status 📋

| Component       | Status        | Performance        | Cost/Month |
| --------------- | ------------- | ------------------ | ---------- |
| **Backend API** | ✅ Deployed   | <200ms response    | $13-25     |
| **Frontend**    | ✅ Deployed   | <800ms load time   | $0-10      |
| **Database**    | ✅ Optimized  | 10GB PostgreSQL    | $15-25     |
| **Cache**       | ✅ Active     | Redis 1GB          | $8         |
| **Monitoring**  | ✅ Configured | Real-time insights | $5-10      |
| **Security**    | ✅ Hardened   | Key Vault + RBAC   | $3-5       |
| **Total**       | ✅ Production | High Performance   | **$44-83** |

### Deployment Regions 🌍

- **Primary**: West US 2 (optimized for West Coast users)
- **Latency**: <20ms CA/WA/OR, <80ms US-wide
- **Availability**: 99.9% SLA with Azure managed services
- **Scaling**: Auto-scale enabled for production workloads

---

<div align="center">

**Built with ❤️ for the fitness community**

[⭐ Star us on GitHub](https://github.com/vedprakash-m/vigor) • [🐛 Report Bug](https://github.com/vedprakash-m/vigor/issues) • [💡 Request Feature](https://github.com/vedprakash-m/vigor/issues)

</div>

# Vigor Fitness Platform

This repository deploys Vigor using a **two-resource-group layout**:

| Resource Group | Contents                                                                                                                                                                                                      |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vigor-rg`     | App Service plan & web apps, Static Web App, Key Vault, Container Registry, Application Insights, Storage Account and all non-persistent resources. You can delete this RG to stop cost when the app is idle. |
| `vigor-db-rg`  | PostgreSQL Flexible Server and `vigor_db` database. This RG remains to preserve data between hibernation cycles.                                                                                              |

## Cost-saving workflow

1. When you don't need the app running, delete the runtime RG:

   ```bash
   az group delete --name vigor-rg --yes --no-wait
   ```

   Database RG stays intact; Azure only bills the database (~$12/mo on B1ms) while everything else is de-allocated.

2. To bring Vigor back online, re-run the GitHub Actions **Deploy** workflow (or execute `infrastructure/bicep/deploy-quota-resilient.sh`). The script recreates `vigor-rg`, while re-using the database in `vigor-db-rg`.

See `infrastructure/bicep/README.md` for full deployment details.
