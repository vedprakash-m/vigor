# 🏋️‍♂️ Vigor - AI-Powered Fitness Platform

> **Transform your fitness journey with personalized AI coaching, smart workout generation, and intelligent progress tracking.**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![React 18](https://img.shields.io/badge/react-18+-blue.svg)](https://reactjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com/)
[![Azure](https://img.shields.io/badge/Azure-Ready-blue.svg)](https://azure.microsoft.com/)

---

## ✨ What is Vigor?

**Vigor** is a modern, AI-powered fitness platform designed to make personal training accessible to everyone. Built with clean architecture principles and cost-optimized for scalability, Vigor delivers personalized workout plans, intelligent coaching, and comprehensive progress tracking.

### 🎯 For Users

- **🤖 Personal AI Coach** - 24/7 fitness guidance and motivation
- **📋 Smart Workout Generation** - Personalized plans based on your goals, equipment, and fitness level
- **📊 Progress Tracking** - Comprehensive analytics and streak monitoring
- **💬 Interactive Coaching** - Real-time chat with AI fitness experts
- **📱 Mobile-Optimized** - PWA support for app-like experience on any device

### 🛠️ For Developers

- **🏗️ Clean Architecture** - Domain-driven design with clear separation of concerns
- **🚀 Modern Stack** - FastAPI + React + TypeScript + PostgreSQL
- **☁️ Cloud-Native** - Azure deployment with Infrastructure as Code
- **🔐 Enterprise Security** - JWT authentication, Key Vault integration, OIDC
- **📊 Observability** - OpenTelemetry tracing, Application Insights monitoring

---

## 🚀 Quick Start

### 🏃‍♂️ Local Development

#### Method 1: VS Code Tasks (Recommended)

1. Open project in VS Code
2. **Task: Install All Dependencies**
3. **Task: Start Backend Server** → http://localhost:8000
4. **Task: Start Frontend Dev Server** → http://localhost:5173

#### Method 2: Manual Setup

```bash
# Backend
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt && python main.py

# Frontend (new terminal)
cd frontend && npm install && npm run dev
```

**🔑 Default Login:** admin@vigor.com / admin123!

### 🐳 Docker Development

```bash
docker-compose up -d
# Access at http://localhost:5173
```

### ☁️ Azure Production Deployment

```bash
# One-command deploy
./scripts/setup-production-secrets.sh
cd infrastructure/bicep && ./deploy.sh
git push origin main  # Triggers automatic deployment
```

---

## 💰 Pricing & AI Providers

### Flexible AI Integration

- **OpenAI GPT-4**: Premium AI coaching experience
- **Google Gemini**: Alternative AI provider with competitive performance
- **Perplexity**: Research-focused AI for nutrition and science-based advice
- **Fallback Mode**: Basic functionality without AI for cost-sensitive users

### Cost-Optimized Architecture

- **Monthly Operating Cost**: ~$43/month on Azure
- **Free Tier Available**: 100 AI requests/month for new users
- **Scalable Pricing**: Pay-as-you-grow model with multiple subscription tiers

---

## 🏗️ Architecture & Technology

### System Architecture

```
React Frontend ← → FastAPI Backend ← → AI Providers
      ↓                    ↓                ↓
Static Web App      App Service       OpenAI/Gemini
                          ↓
                  PostgreSQL Database
```

### Technology Stack

- **Frontend**: React 18, TypeScript 5, Chakra UI, Zustand, PWA
- **Backend**: FastAPI, SQLAlchemy, Alembic, Pydantic, JWT
- **Database**: PostgreSQL (Azure Flexible Server)
- **Infrastructure**: Azure App Service, Key Vault, Application Insights
- **AI**: OpenAI GPT-4, Google Gemini, Perplexity APIs
- **DevOps**: GitHub Actions, Azure Bicep, Docker

### Design Principles

- **Clean Architecture**: Domain, Application, Infrastructure layers
- **Cost Optimization**: Single-slot deployment, efficient resource usage
- **Provider Agnostic**: Seamless switching between AI providers
- **Progressive Enhancement**: Core functionality works without AI

---

## 🧪 Testing & Quality

### Automated Testing

```bash
# Run full test suite
./scripts/enhanced-local-validation.sh

# Backend tests
cd backend && pytest -v --cov=.

# Frontend tests
cd frontend && npm test

# E2E tests
npm run test:e2e
```

### Quality Metrics

- **Backend Coverage**: 50%+ (target: 80%)
- **Frontend Coverage**: 31%+ (target: 80%)
- **Code Quality**: Black, Ruff, ESLint, TypeScript strict mode
- **Security**: Bandit, Safety, Gitleaks scanning

---

## 🚀 Deployment & Operations

### Automated CI/CD

- **Simplified Pipeline**: Quality checks → Build → Deploy → Verify
- **Single-Slot Strategy**: Direct production deployment for cost efficiency
- **Health Monitoring**: Automated deployment verification
- **Rollback Capability**: Emergency rollback procedures

### Infrastructure as Code

- **Azure Bicep**: Modern, type-safe infrastructure templates
- **Cost-Optimized**: Basic SKUs, single resource group strategy
- **Security**: Managed identities, Key Vault integration
- **Monitoring**: Application Insights, Log Analytics

### Performance Features

- **Caching**: Redis for sessions and API responses
- **CDN**: Azure Static Web Apps for frontend assets
- **Database**: Connection pooling, query optimization
- **API**: Async FastAPI with Pydantic validation

---

## 📚 Documentation & Support

### Development Resources

- **📖 Complete Documentation**: [docs/metadata.md](docs/metadata.md)
- **🏗️ Architecture Decisions**: [docs/adr/](docs/adr/)
- **🤝 Contributing Guide**: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)
- **🔐 Security Guide**: [docs/secrets_management_guide.md](docs/secrets_management_guide.md)

### API Documentation

- **Interactive API Docs**: http://localhost:8000/docs (Swagger UI)
- **ReDoc Format**: http://localhost:8000/redoc
- **OpenAPI Schema**: Fully documented REST API

### Key Scripts

- **Local Validation**: `./scripts/enhanced-local-validation.sh`
- **Health Checks**: `./scripts/health-check.sh`
- **E2E Testing**: `./scripts/test-e2e-local.sh`
- **Deployment**: `./scripts/setup-production-secrets.sh`

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/CONTRIBUTING.md) for details.

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch
3. **Run** local validation: `./scripts/enhanced-local-validation.sh`
4. **Submit** a pull request with tests and documentation

### Code Standards

- **Python**: Black formatting, Ruff linting, mypy type checking
- **TypeScript**: ESLint, Prettier, strict type checking
- **Testing**: Minimum 50% coverage, integration tests required
- **Documentation**: Update relevant docs with changes

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0** (AGPL-3.0).

**What this means:**

- ✅ **Commercial Use**: You can use this software commercially
- ✅ **Modification**: You can modify and improve the code
- ✅ **Distribution**: You can distribute copies of the software
- ✅ **Private Use**: You can use this for private projects

**Requirements:**

- 📋 **Include License**: Include the original license in distributions
- 📝 **State Changes**: Document any changes you make
- 🔓 **Disclose Source**: If you run this as a web service, you must make your source code available
- 📑 **Same License**: Derivative works must use the same license

For more details, see the [LICENSE](LICENSE) file.

**Commercial Licensing**: If you need different licensing terms for commercial use without source disclosure requirements, please contact us.

---

## 🙏 Acknowledgments

- **FastAPI**: For the amazing Python web framework
- **React Team**: For the incredible frontend library
- **Azure**: For reliable cloud infrastructure
- **OpenAI/Google**: For powerful AI capabilities
- **Open Source Community**: For the amazing tools and libraries

---

**Built with ❤️ for the fitness community**

_Transform your fitness journey today with Vigor - where AI meets personalized training._

# Access services:

# - Backend: http://localhost:8000

# - Frontend: http://localhost:5173

# - Database: localhost:5432

````

## 🏗️ Architecture Overview

```mermaid
flowchart TD
  subgraph Frontend
    A[React 18 + Vite] --> B[Zustand Store]
    B --> C[REST API]
  end

  subgraph Backend [FastAPI Backend]
    C --> D[LLM Gateway Facade]
    D --> E[Redis Cache]
    D --> F[Celery Worker]
    D --> G[PostgreSQL]
  end

  F -->|Health-checks| D
  D -->|Traces| H(OpenTelemetry Collector)
````

**Clean Architecture** with distinct layers:

- **Domain:** Core business logic and entities
- **Application:** Use cases and orchestration (LLM facade, routing, validation)
- **Infrastructure:** Database repositories, cache adapters, external services
- **API:** FastAPI routes and middleware

## 🛡️ Quality Gates

- **Code Quality:** Ruff, Black, ESLint, Prettier
- **Type Safety:** MyPy strict + TypeScript strict
- **Testing:** Pytest/Jest coverage ≥ 80% enforced in CI
- **Security:** Bandit, Safety, pre-commit hooks
- **Architecture:** ADR documentation, clean architecture principles

## 🏗️ Technology Stack

### Backend

- **Framework:** FastAPI + Python 3.9+
- **Database:** PostgreSQL with SQLAlchemy ORM
- **AI/LLM:** Multi-provider support (OpenAI, Gemini, Perplexity)
- **Caching:** Redis with distributed cache adapter
- **Background Tasks:** Celery with Redis broker
- **Observability:** OpenTelemetry tracing and structured logging

### Frontend

- **Framework:** React 18 + TypeScript + Vite
- **UI Library:** Chakra UI with responsive design
- **State Management:** Zustand for global state
- **Development:** Storybook for component development
- **Testing:** Jest + Testing Library + Playwright E2E

### DevOps & Infrastructure

- **Containerization:** Docker + Docker Compose
- **CI/CD:** GitHub Actions with quality gates
- **Cloud:** Azure deployment with Bicep IaC
- **Monitoring:** Application Insights, health checks

## 📚 Documentation

- **[Getting Started](docs/getting-started.md)** - Complete setup guide
- **[Architecture](docs/architecture.md)** - Technical deep dive
- **[ADR Documentation](docs/adr/)** - Architecture decision records
- **[Metadata & Roadmap](docs/metadata.md)** - Project status and roadmap
- **[API Docs](http://localhost:8000/docs)** - Interactive API reference (when running locally)
- **[Contributing](docs/CONTRIBUTING.md)** - How to contribute

## 🚀 Development Scripts

The project includes VS Code tasks for common development workflows:

- **Install All Dependencies** - Sets up both backend and frontend
- **Start Backend Server** - Runs FastAPI with proper environment
- **Start Frontend Dev Server** - Runs React development server
- **Run Backend Tests** - Executes Python test suite
- **Run Frontend Tests** - Executes JavaScript/TypeScript tests
- **Format Code** - Runs Black, isort for backend; ESLint for frontend

## 🔧 Environment Configuration

### Backend Environment Variables

```env
# Required
DATABASE_URL=postgresql://user:pass@localhost:5432/vigor
OPENAI_API_KEY=your_openai_key

# Optional
REDIS_URL=redis://localhost:6379/0
DEBUG=true
TESTING=false
LLM_PROVIDER=openai  # openai, gemini, perplexity, fallback
```

### Frontend Environment Variables

```env
VITE_API_BASE_URL=http://localhost:8000
```

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guide](docs/CONTRIBUTING.md) and follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following our coding standards
4. Run tests and ensure quality gates pass
5. Commit your changes (`git commit -m 'feat: add amazing feature'`)
   _Transform your fitness journey today with Vigor - where AI meets personalized training._
