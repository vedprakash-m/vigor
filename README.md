# 🏋️‍♂️ Vigor - AI-Powered Fitness Platform

> **Transform your fitness journey with personalized AI coaching, smart workout generation, and intelligent progress tracking.**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![React 19](https://img.shields.io/badge/react-19+-blue.svg)](https://reactjs.org/)
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
- **📱 Mobile-Optimized** - Responsive design with service worker caching

### 🛠️ For Developers

- **🏗️ Clean Architecture** - Domain-driven design with clear separation of concerns
- **🚀 Modern Stack** - FastAPI + React + TypeScript + PostgreSQL
- **☁️ Cloud-Native** - Azure deployment with Infrastructure as Code
- **🔐 Enterprise Security** - JWT authentication, Key Vault integration
- **📊 Observability** - Comprehensive monitoring and health checks

---

## 🚀 Quick Start

### 🏃‍♂️ Local Development

1. **Clone the repository**

   ```bash
   git clone <your-repository-url>
   cd vigor
   ```

2. **Using VS Code Tasks (Recommended)**

   - Open project in VS Code
   - **Ctrl+Shift+P** → "Tasks: Run Task"
   - **Install All Dependencies** → **Start Backend Server** → **Start Frontend Dev Server**

3. **Manual Setup**

   ```bash
   # Backend
   cd backend
   python -m venv venv && source venv/bin/activate
   pip install -r requirements.txt
   LLM_PROVIDER=fallback OPENAI_API_KEY=sk-placeholder python main.py  # http://localhost:8000

   # Frontend (new terminal)
   cd frontend && npm install && npm run dev  # http://localhost:5173
   ```

**🔑 Default Login:** `admin@vigor.com` / `admin123!`

### 🐳 Docker Development

```bash
docker-compose up -d
# Access at http://localhost:5173
```

### ☁️ Azure Production Deployment

```bash
# Setup secrets and deploy infrastructure
./scripts/setup-production-secrets.sh
cd infrastructure/bicep && ./deploy.sh

# Trigger automatic deployment
git push origin main
```

---

## 💰 Pricing & AI Integration

### Flexible AI Providers

- **OpenAI GPT-3.5:** Premium AI coaching experience
- **Google Gemini 2.5 Flash:** Cost-effective alternative with competitive performance
- **Perplexity Llama 3.1:** Research-focused AI for nutrition and science-based advice
- **Fallback Mode:** Basic functionality without AI for cost-sensitive deployments

### Cost-Optimized Azure Deployment

- **Monthly Operating Cost:** ~$20-43/month (F1 free tier or B1 Basic App Service + Basic PostgreSQL)
- **Single-Slot Strategy:** Direct production deployment for cost efficiency
- **Scalable Architecture:** Pay-as-you-grow with multiple subscription tiers

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

**Backend:**

- **Framework:** FastAPI with Python 3.12+
- **AI Integration:** OpenAI GPT-4, Google Gemini, Perplexity APIs
- **Authentication:** JWT tokens with Azure Key Vault
- **Database:** PostgreSQL with SQLAlchemy ORM

**Frontend:**

- **Framework:** React 19 + TypeScript 5 + Vite
- **UI Library:** Chakra UI with responsive design
- **State Management:** Zustand for global state
- **PWA Ready:** Service worker included for enhanced caching

**Infrastructure:**

- **Cloud:** Azure App Service, Static Web Apps, PostgreSQL Flexible Server
- **IaC:** Azure Bicep templates
- **Monitoring:** Application Insights, health checks
- **CI/CD:** GitHub Actions with quality gates

### Design Principles

- **Clean Architecture:** Domain, Application, Infrastructure layers
- **Cost Optimization:** Single-slot deployment, efficient resource usage
- **Provider Agnostic:** Seamless switching between AI providers
- **Progressive Enhancement:** Core functionality works without AI

---

## 🧪 Testing & Quality

### Automated Testing

```bash
# Run comprehensive validation
./scripts/enhanced-local-validation.sh

# Backend tests with coverage
cd backend && pytest -v --cov=.

# Frontend tests
cd frontend && npm test

# End-to-end tests
cd frontend && npm run test:e2e
```

### Quality Metrics & Tools

- **Code Quality:** Black, Ruff (Python) | ESLint, Prettier (TypeScript)
- **Type Safety:** MyPy strict mode + TypeScript strict mode
- **Security:** Bandit, Safety scanning, pre-commit hooks
- **Test Coverage:** Backend 51%+ | Frontend 31%+ (target: 80% both)
- **CI/CD:** Quality gates enforced on every commit

---

## 🚀 Deployment & Operations

### Simplified CI/CD Pipeline

Our streamlined deployment process focuses on quality and reliability:

1. **Quality Checks** → Code formatting, linting, type checking, security scans
2. **Testing** → Unit tests, integration tests, build verification
3. **Deploy** → Automatic deployment to Azure on push to main
4. **Verify** → Health checks and deployment validation

### Infrastructure as Code

- **Azure Bicep:** Modern, type-safe infrastructure templates
- **Cost-Optimized:** Basic SKUs, efficient resource allocation
- **Security:** Managed identities, Key Vault integration
- **Monitoring:** Application Insights for comprehensive observability

### Available VS Code Tasks

- **Install All Dependencies** - Complete project setup
- **Start Backend Server** - FastAPI with hot reload
- **Start Frontend Dev Server** - React with Vite
- **Run Backend/Frontend Tests** - Execute test suites
- **Format Backend/Frontend Code** - Apply code formatting standards

---

## 📚 Documentation & API

### Development Resources

- **📖 [Complete Documentation](docs/metadata.md)** - Project overview, roadmap, and technical details
- **🏗️ [Architecture Decisions](docs/adr/)** - ADR records for major technical decisions
- **🤝 [Contributing Guide](docs/CONTRIBUTING.md)** - How to contribute to the project
- **🔐 [Security Guide](docs/secrets_management_guide.md)** - Security best practices

### API Documentation

- **Interactive API Docs:** http://localhost:8000/docs (Swagger UI)
- **ReDoc Format:** http://localhost:8000/redoc
- **OpenAPI Schema:** Fully documented REST API with examples

### Key Scripts

- **Local Validation:** `./scripts/enhanced-local-validation.sh`
- **Health Checks:** `./scripts/health-check.sh`
- **Production Setup:** `./scripts/setup-production-secrets.sh`

---

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guide](docs/CONTRIBUTING.md) for detailed information.

### Development Workflow

1. **Fork** the repository and create a feature branch
2. **Make changes** following our coding standards
3. **Run validation** with `./scripts/enhanced-local-validation.sh`
4. **Submit** a pull request with tests and documentation

### Code Standards

- **Python:** Black formatting, Ruff linting, MyPy type checking
- **TypeScript:** ESLint, Prettier, strict type checking
- **Testing:** Maintain/improve test coverage, include integration tests
- **Documentation:** Update relevant docs with significant changes

---

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0** (AGPL-3.0).

**What this means:**

- ✅ **Commercial Use:** You can use this software commercially
- ✅ **Modification:** You can modify and improve the code
- ✅ **Distribution:** You can distribute copies of the software
- ✅ **Private Use:** You can use this for private projects

**Requirements:**

- 📋 **Include License:** Include the original license in distributions
- 📝 **State Changes:** Document any changes you make
- 🔓 **Disclose Source:** If you run this as a web service, you must make your source code available
- 📑 **Same License:** Derivative works must use the same license

For more details, see the [LICENSE](LICENSE) file.

---

## 🙏 Acknowledgments

- **FastAPI** - For the amazing Python web framework
- **React Team** - For the incredible frontend library
- **Azure** - For reliable cloud infrastructure
- **OpenAI/Google** - For powerful AI capabilities
- **Open Source Community** - For the amazing tools and libraries

---

**Built with ❤️ for the fitness community**

_Transform your fitness journey today with Vigor - where AI meets personalized training._
