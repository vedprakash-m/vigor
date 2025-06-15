# 🏋️‍♂️ Vigor - AI-Powered Fitness Coaching Platform

> **Transform your fitness journey with personalized AI coaching, smart workout generation, and intelligent progress tracking.**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![React 18](https://img.shields.io/badge/react-18+-blue.svg)](https://reactjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com/)

---

## ✨ What is Vigor?

Vigor is a modern fitness platform that brings the power of AI coaching to everyone. Whether you're a beginner starting your fitness journey or an experienced athlete looking to optimize your training, Vigor adapts to your needs, equipment, and goals.

### 🎯 For Fitness Enthusiasts

- **🤖 Personal AI Coach**: Get real-time advice, motivation, and guidance tailored to your fitness level
- **📋 Smart Workout Plans**: Automatically generated workouts based on your goals, available equipment, and time
- **📊 Progress Tracking**: Monitor your journey with intelligent analytics and insights
- **💬 Interactive Chat**: Ask questions, get form tips, and receive encouragement whenever you need it
- **📱 Mobile-First**: Train anywhere with a responsive, PWA-ready experience

### 🛠️ For Developers

- **� Modern Tech Stack**: FastAPI + React + TypeScript with full type safety
- **🤖 Multi-LLM Support**: Flexible AI provider integration (OpenAI, Gemini, Perplexity)
- **☁️ Cloud-Ready**: Production-ready Azure deployment with Infrastructure as Code
- **� Enterprise Security**: JWT authentication, Azure Key Vault, and managed identities
- **📈 Scalable Architecture**: Modular design with clean separation of concerns

---

## 🚀 Quick Start

### Option 1: Try the Demo (No Setup Required)

Visit our live demo at [vigor-demo.com](https://vigor-demo.com) and start chatting with your AI fitness coach immediately.

### Option 2: Run Locally

**Prerequisites**: Python 3.9+, Node.js 18+, Git

```bash
# Clone the repository
git clone https://github.com/vedprakash-m/vigor.git
cd vigor

# Start backend (Terminal 1)
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py

# Start frontend (Terminal 2)
cd frontend
npm install
npm run dev
```

**Access the app**: http://localhost:5173
**API docs**: http://localhost:8001/docs
**Default login**: admin@vigor.com / admin123!

### Option 3: VS Code Development

1. Open the project in VS Code
2. Use Command Palette → "Tasks: Run Task"
3. Select "Install All Dependencies" then "Start Backend Server" and "Start Frontend Dev Server"

---

## 🌟 Key Features

### 🤖 AI-Powered Coaching

- **Smart Conversations**: Natural chat interface with context-aware responses
- **Personalized Workouts**: AI-generated plans based on your profile and goals
- **Real-time Guidance**: Get instant answers to form, nutrition, and training questions
- **Progress Analysis**: AI-driven insights on your fitness journey

### 💰 Flexible Pricing Tiers

- **Free Tier**: 100 AI requests/month - perfect for getting started
- **Premium**: 1,000 requests/month + advanced features
- **Unlimited**: No limits + priority support
- **Usage Tracking**: Real-time monitoring of your AI usage

### � Smart AI Integration

- **Multi-Provider Support**: Choose between OpenAI, Google Gemini, or Perplexity
- **Automatic Fallback**: Always works, even without API keys configured
- **Provider Health Monitoring**: Real-time status of AI services
- **Cost Optimization**: Smart provider switching based on budget and needs

### 📱 Modern Experience

- **Responsive Design**: Perfect on mobile, tablet, and desktop
- **Progressive Web App**: Install directly on your device
- **Dark/Light Mode**: Comfortable viewing anytime
- **Fast & Reliable**: Optimized for performance

---

## 🏗️ Technology Stack

| Component          | Technology                 | Purpose                                  |
| ------------------ | -------------------------- | ---------------------------------------- |
| **Backend**        | FastAPI + Python 3.9+      | RESTful API with automatic documentation |
| **Frontend**       | React 18 + TypeScript      | Modern, type-safe user interface         |
| **Database**       | PostgreSQL + SQLAlchemy    | Reliable data storage with ORM           |
| **AI Integration** | Multi-provider abstraction | Flexible LLM support                     |
| **Authentication** | JWT + refresh tokens       | Secure user sessions                     |
| **Infrastructure** | Azure + Bicep              | Cloud deployment with IaC                |
| **UI Framework**   | Chakra UI v3               | Beautiful, accessible components         |
| **Build Tools**    | Vite + TypeScript          | Fast development and builds              |

---

## 🚀 Deployment

### Cloud Deployment (Azure)

Deploy to Azure with one command:

```bash
# Set up secrets and deploy infrastructure
./scripts/setup-production-secrets.sh
cd infrastructure/bicep && ./deploy.sh
git push origin main  # Triggers automatic deployment
```

**What gets deployed:**

- FastAPI backend on Azure App Service
- React frontend on Azure Static Web Apps
- PostgreSQL database with automatic backups
- Redis cache for session management
- Application monitoring and logging

### Self-Hosting

Vigor can be deployed on any cloud provider or on-premises server. See [docs/deployment.md](docs/deployment.md) for detailed instructions.

---

## 📚 Documentation

- **[Getting Started Guide](docs/getting-started.md)** - Complete setup and configuration
- **[API Documentation](http://localhost:8001/docs)** - Interactive API reference (when running locally)
- **[Deployment Guide](docs/deployment.md)** - Production deployment instructions
- **[LLM Setup](backend/LLM_SETUP.md)** - Configure AI providers
- **[Contributing](docs/CONTRIBUTING.md)** - How to contribute to the project
- **[Architecture Overview](docs/architecture.md)** - Technical deep dive

---

## 🤝 Contributing

We welcome contributions from developers of all skill levels! Whether you want to:

- 🐛 **Report bugs** or suggest features
- 💻 **Submit code improvements**
- 📝 **Improve documentation**
- 🧪 **Add tests** or enhance quality

Please read our [Contributing Guide](docs/CONTRIBUTING.md) to get started.

### Quick Development Setup

```bash
# Install dependencies
./scripts/lightning-validation.sh  # Fast validation
Task: Install All Dependencies     # VS Code task

# Run tests
Task: Run Backend Tests
Task: Run Frontend Tests

# Format code
Task: Format Backend Code
Task: Format Frontend Code
```

---

## 🔗 Links

- **Live Demo**: [vigor-demo.com](https://vigor-demo.com)
- **GitHub**: [github.com/vedprakash-m/vigor](https://github.com/vedprakash-m/vigor)
- **Issues**: [Report bugs or request features](https://github.com/vedprakash-m/vigor/issues)
- **Discussions**: [Community discussions](https://github.com/vedprakash-m/vigor/discussions)

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPLv3)**.

**Key points:**

- ✅ Free to use, modify, and distribute
- ✅ Commercial use allowed
- ⚠️ Source code must be disclosed when distributed
- ⚠️ Network use requires source disclosure

See the [LICENSE](LICENSE) file for full details.

---

<div align="center">

**Built with ❤️ for the fitness community**

[⭐ Star us on GitHub](https://github.com/vedprakash-m/vigor) • [🐛 Report Bug](https://github.com/vedprakash-m/vigor/issues) • [💡 Request Feature](https://github.com/vedprakash-m/vigor/issues)

**Transform your fitness journey today!**

</div>

---

## 🚀 Quick Start

### Prerequisites

- **Python 3.9+**
- **Node.js 18+**
- **Git**
- **Azure subscription** (for cloud deployment only)

### Run with VS Code Tasks

The easiest way to get started is using VS Code tasks:

1. **Install Dependencies**

   ```
   # Install all dependencies (backend and frontend)
   Task: Install All Dependencies
   ```

2. **Start Services**

   ```
   # Start backend server
   Task: Start Backend Server

   # In a new terminal, start frontend dev server
   Task: Start Frontend Dev Server
   ```

3. **Run Tests**

   ```
   # Run backend tests
   Task: Run Backend Tests

   # Run frontend tests
   Task: Run Frontend Tests
   ```

### Manual Setup

#### 1. Clone Repository

```bash
git clone https://github.com/yourusername/vigor.git
cd vigor
```

#### 2. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment (optional - app works without API keys)
export LLM_PROVIDER=fallback  # Use OpenAI, Gemini, Perplexity, or Fallback
export OPENAI_API_KEY=your-api-key-here  # If using OpenAI

# Run database migrations
alembic upgrade head

# Start the server
python main.py
```

#### 3. Frontend Setup

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

# 3. Deploy infrastructure to Azure (single region deployment)
cd infrastructure/bicep && ./deploy.sh

# 4. Push to trigger application deployment
git push origin main
```

### **Infrastructure Features**

- **🏗️ Azure Bicep**: Modern Infrastructure as Code (migrated from Terraform)
- **🔐 OIDC Authentication**: Secure GitHub Actions deployment without client secrets
- **🌍 Central US Deployment**: Single region for simplicity and cost efficiency
- **💰 Cost Optimized**: FREE tier App Service + minimal database costs
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

- [Project Metadata](docs/metadata.md): Technical details, deployment strategies, and architecture overview
- [LLM Provider Setup Guide](backend/LLM_SETUP.md): How to configure different LLM providers
- [Development Workflow](docs/dev_pr_mgmt.md): Full description of development process and CI/CD pipeline
- [Security Guide](docs/secrets_management_guide.md): Security practices and secret management approach
- [CI Optimization](docs/ci_optimization_guide.md): How we optimize our continuous integration processes
- [Workflow Testing](docs/workflow_testing_guide.md): Testing our GitHub workflows and automation
- [Agent Communication](docs/agent_communication_guide.md): How to communicate with AI assistants
- [User Experience](docs/User_Experience.md): Our approach to UX design and principles
- [API Reference](http://localhost:8000/docs): Live API documentation
- [Contributing Guide](docs/CONTRIBUTING.md): How to contribute to Vigor

### Getting API Keys

- [Google Gemini (Free Tier)](https://makersuite.google.com/app/apikey)
- [Perplexity API](https://docs.perplexity.ai/)
- [OpenAI Platform](https://platform.openai.com/api-keys)

### Technical Documentation

- [Database Schema](backend/database/models.py) - Complete database models with tier system
- [Usage Tracking Service](backend/api/services/usage_tracking.py) - AI usage monitoring
- [Tier Management API](backend/api/routes/tiers.py) - Tier upgrade and analytics endpoints
- [Migration Files](backend/alembic/versions/) - Database migration history
- [Infrastructure Templates](infrastructure/bicep/) - Azure Bicep infrastructure as code templates

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
- **✅ Single Region Deployment**: Central US for simplicity and cost efficiency
- **✅ Cost Optimization**: FREE tier hosting + minimal database costs
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

### Deployment Region 🌍

- **Primary**: Central US (single region for cost efficiency)
- **Latency**: Optimized for US-wide access
- **Availability**: 99.9% SLA with Azure managed services
- **Scaling**: Auto-scale enabled for production workloads

---

<div align="center">

**Built with ❤️ for the fitness community**

[⭐ Star us on GitHub](https://github.com/vedprakash-m/vigor) • [🐛 Report Bug](https://github.com/vedprakash-m/vigor/issues) • [💡 Request Feature](https://github.com/vedprakash-m/vigor/issues)

</div>

# Vigor Fitness Platform

This repository deploys Vigor using a **two-resource-group layout**:

| Resource Group | Contents                                                                                                                                                                                        |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vigor-rg`     | App Service plan & web apps, Static Web App, Key Vault, Container Registry, Application Insights and other non-persistent resources. You can delete this RG to stop cost when the app is idle.  |
| `vigor-db-rg`  | PostgreSQL Flexible Server, Storage Account (blob/data), and `vigor_db` database. This RG remains to preserve data between hibernation cycles and keeps all persistent data resources together. |

## Cost-saving workflow

1. When you don't need the app running, delete the runtime RG:

   ```bash
   az group delete --name vigor-rg --yes --no-wait
   ```

   Database RG stays intact; Azure only bills the database (~$12/mo on B1ms) while everything else is de-allocated.

2. To bring Vigor back online, re-run the GitHub Actions **Deploy** workflow (or execute `infrastructure/bicep/deploy-quota-resilient.sh`). The script recreates `vigor-rg`, while re-using the database in `vigor-db-rg`.

See `infrastructure/bicep/README.md` for full deployment details.
