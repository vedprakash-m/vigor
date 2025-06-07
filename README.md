# Vigor - AI-Powered Fitness Companion

[![CI/CD Pipeline](https://github.com/vedprakashmishra/vigor/actions/workflows/ci_cd_pipeline.yml/badge.svg)](https://github.com/vedprakashmishra/vigor/actions/workflows/ci_cd_pipeline.yml)
[![Type Safety](https://img.shields.io/badge/mypy-100%25-green.svg)](https://mypy.readthedocs.io/)
[![Code Quality](https://img.shields.io/badge/code%20quality-A+-brightgreen.svg)](https://github.com/vedprakashmishra/vigor)
[![Security Scan](https://img.shields.io/badge/security-scanned-green.svg)](https://github.com/vedprakashmishra/vigor/security)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Vigor is an enterprise-grade AI-powered fitness and wellness companion designed to provide personalized, intelligent coaching and support for users' health journeys. The platform combines artificial intelligence, enterprise LLM orchestration, and behavioral science to deliver a proactive, motivating, and comprehensive fitness experience.

## 🎯 Latest Achievements

**🔥 MyPy Type Safety Complete** - Achieved **100% type safety** across all 53 source files with zero MyPy errors
**🚀 Enterprise-Ready Codebase** - Production-ready type annotations and systematic model validation patterns
**⚡ CI/CD Pipeline Operational** - Zero flake8 violations, automated testing, and security scanning
**🛡️ Security Hardened** - Comprehensive vulnerability scanning and modern authentication patterns

## 🚀 Key Features

### MVP Features (Production Ready)

- **🔐 Secure Authentication**: JWT-based auth with refresh token rotation
- **🏋️ AI Workout Planning**: LLM-generated personalized workout plans
- **📊 Progress Tracking**: Comprehensive workout logging with visual analytics
- **🤖 AI Coaching**: Daily motivation, Q&A system, workout guidance
- **👥 User Tier Management**: FREE/PREMIUM/UNLIMITED tiers with usage limits
- **⚙️ Admin Dashboard**: Real-time system management and analytics
- **🔧 Enterprise LLM Orchestration**: Multi-provider AI with cost optimization

### Upcoming Features

- **📹 Computer Vision Form Analysis**: AI-powered exercise form feedback
- **💓 Recovery Readiness**: HRV + RPE + sleep data integration
- **⌚ Wearables Integration**: Apple Health, Garmin, Google Fit
- **🗣️ Voice-Guided Workouts**: AI-narrated sessions with coach personalities

## 🏗️ Technology Stack

### Frontend

- **React 18** with TypeScript
- **Vite** build system
- **Chakra UI** component library
- **Jest + React Testing Library**

### Backend

- **Python 3.12+** with FastAPI
- **SQLAlchemy 2.0** (async ORM)
- **PostgreSQL** (production) / SQLite (development)
- **Alembic** database migrations
- **Pydantic v2** data validation
- **MyPy** 100% type safety coverage

### AI & LLM Integration

- **Multi-Provider Support**: OpenAI GPT-4, Google Gemini, Perplexity
- **Enterprise Orchestration**: Intelligent routing, fallback, cost optimization
- **Circuit Breaker Patterns**: Resilience and high availability
- **Azure Key Vault**: Secure API key management
- **Type-Safe AI Integration**: Comprehensive type annotations for AI operations

### Infrastructure

- **Azure Cloud**: Container Registry, App Service, PostgreSQL
- **Terraform**: Infrastructure as Code
- **GitHub Actions**: CI/CD with security scanning
- **Docker**: Containerized deployment

## 🚦 Quick Start

### Prerequisites

- Python 3.12+
- Node.js 20+
- Git

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/vedprakashmishra/vigor.git
   cd vigor
   ```

2. **Set up backend**

   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Set up frontend**

   ```bash
   cd frontend
   npm install
   ```

4. **Initialize database**
   ```bash
   cd backend
   alembic upgrade head
   python create_admin_user.py  # Creates admin user
   ```

### Development

1. **Start backend server**

   ```bash
   cd backend
   source venv/bin/activate
   LLM_PROVIDER=fallback python main.py
   ```

2. **Start frontend development server**

   ```bash
   cd frontend
   npm run dev
   ```

3. **Access the application**
   - Frontend: http://localhost:5173
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the backend directory:

```env
# Database
DATABASE_URL=sqlite:///./vigor.db

# Security
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# LLM Providers (Optional - Fallback provider works without keys)
OPENAI_API_KEY=sk-your-openai-key
GOOGLE_AI_API_KEY=your-gemini-key
PERPLEXITY_API_KEY=your-perplexity-key

# Azure Key Vault (Production)
KEY_VAULT_URL=https://your-vault.vault.azure.net/
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
AZURE_TENANT_ID=your-tenant-id
```

### User Tiers

- **FREE**: 10 daily AI requests, $5 budget
- **PREMIUM**: 50 daily AI requests, $25 budget
- **UNLIMITED**: 1000 daily AI requests, $100 budget

## 🧪 Testing

### Backend Tests

```bash
cd backend
source venv/bin/activate
pytest -v
```

### Frontend Tests

```bash
cd frontend
npm test
```

### Code Quality

```bash
# Backend formatting and type checking
cd backend && black . && isort . && mypy --config-file mypy.ini .

# Frontend linting
cd frontend && npm run lint:fix
```

### Type Safety Verification

```bash
# Verify 100% MyPy compliance
cd backend
source venv/bin/activate
mypy --config-file mypy.ini .
# Should show: Success: no issues found in 53 source files
```

## 🚀 Deployment

### Production Deployment (Azure)

1. **Configure GitHub Secrets** (see `docs/DEPLOYMENT_GUIDE.md`)
2. **Push to main branch** - CI/CD pipeline automatically deploys
3. **Monitor deployment** in GitHub Actions

### Manual Deployment

1. **Build containers**

   ```bash
   cd backend && docker build -t vigor-backend .
   ```

2. **Deploy infrastructure**
   ```bash
   cd infrastructure/terraform
   terraform init
   terraform plan
   terraform apply
   ```

## 📊 Architecture

### System Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React App     │    │   FastAPI       │    │   PostgreSQL    │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ LLM Orchestration│
                    │ Gateway          │
                    └─────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  OpenAI     │    │   Gemini    │    │ Perplexity  │
│  GPT-4      │    │   Pro       │    │   API       │
└─────────────┘    └─────────────┘    └─────────────┘
```

### Key Components

- **LLM Gateway**: Enterprise-grade orchestration with intelligent routing
- **User Tier System**: Usage limits and budget management
- **Admin Dashboard**: Real-time monitoring and system control
- **Security Layer**: JWT auth, input validation, encryption

## 📚 Documentation

- [**PROJECT_METADATA.md**](docs/PROJECT_METADATA.md) - Comprehensive project documentation
- [**DEPLOYMENT_GUIDE.md**](docs/DEPLOYMENT_GUIDE.md) - Production deployment instructions
- [**LLM_ORCHESTRATION_USAGE_GUIDE.md**](docs/LLM_ORCHESTRATION_USAGE_GUIDE.md) - AI system usage
- [**ENTERPRISE_ADMIN_SYSTEM.md**](docs/ENTERPRISE_ADMIN_SYSTEM.md) - Admin dashboard guide
- [**SECURITY_SCAN_REPORT.md**](docs/SECURITY_SCAN_REPORT.md) - Security analysis

## 🔒 Security

- **Authentication**: JWT with refresh token rotation
- **Authorization**: Role-based access control (user/admin)
- **Data Protection**: Encryption at rest and in transit
- **Input Validation**: Comprehensive sanitization across all endpoints
- **Security Scanning**: Automated vulnerability detection in CI/CD
- **GDPR Compliance**: Full data protection compliance

## 🏆 Production Status

### ✅ Completed

- **🎯 MyPy Type Safety**: **100% completion** - Zero type errors across 53 source files
- **🚀 CI/CD Pipeline**: Fully operational with automated testing and deployment
- **🔍 Security Scanning**: Trivy, Bandit, CodeQL integrated with zero critical issues
- **📋 Code Quality**: Black, isort, ESLint with pre-commit hooks - zero violations
- **☁️ Azure Infrastructure**: Container Registry, App Service, Key Vault ready
- **🤖 Enterprise LLM System**: Multi-provider orchestration with cost optimization
- **👥 User Tier Management**: Complete freemium model implementation
- **📊 Admin Dashboard**: Real-time system monitoring and control
- **🔒 Security Hardening**: JWT auth, input validation, encryption at rest/transit

### Technical Excellence Metrics

- **Type Safety**: 100% MyPy compliance (53/53 files)
- **Code Quality**: 0 flake8 violations (reduced from 35)
- **Test Coverage**: Frontend and backend test suites passing
- **Security Score**: 0 critical vulnerabilities detected
- **CI/CD Health**: All pipeline jobs operational

### 🔄 In Progress

- **Production Database**: PostgreSQL deployment
- **Monitoring**: Application insights and logging
- **Performance**: Load testing and optimization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Standards

- **Backend**: Black formatting, isort imports, MyPy type checking, pytest testing
- **Frontend**: ESLint rules, Jest testing, TypeScript strict mode
- **Git**: Conventional commits, pre-commit hooks
- **Type Safety**: 100% MyPy compliance required for all new code
- **Code Quality**: Zero tolerance for linting violations

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- **Issues**: [GitHub Issues](https://github.com/vedprakashmishra/vigor/issues)
- **Documentation**: [Project Docs](docs/)
- **API Reference**: http://localhost:8000/docs (when running locally)

---

**Built with ❤️ using modern technologies for enterprise-grade fitness coaching**
