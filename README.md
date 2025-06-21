# 🏋️‍♂️ Vigor - AI-Powered Fitness Platform

> **Transform your fitness journey with personalized AI coaching, smart workout generation, and intelligent progress tracking.**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)
[![React 19](https://img.shields.io/badge/react-19+-blue.svg)](https://reactjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com/)
[![Azure](https://img.shields.io/badge/Azure-Ready-blue.svg)](https://azure.microsoft.com/)

---

## ✨ Overview

**Vigor** is a modern, AI-powered fitness platform that makes personal training accessible to everyone. Built with clean architecture principles and cost-optimized for scalability, Vigor delivers personalized workout plans, intelligent coaching, and comprehensive progress tracking.

### Key Features

- **🤖 Personal AI Coach** - 24/7 fitness guidance powered by OpenAI GPT, Google Gemini, or Perplexity
- **📋 Smart Workout Generation** - Personalized plans based on goals, equipment, and fitness level
- **📊 Progress Tracking** - Comprehensive analytics with streak monitoring and gamification
- **💬 Interactive Coaching** - Real-time chat with AI fitness experts
- **📱 Mobile-Optimized** - Responsive PWA design with offline capabilities

### Technology Stack

- **Backend:** FastAPI + Python 3.12+ + PostgreSQL + SQLAlchemy
- **Frontend:** React 19 + TypeScript 5 + Chakra UI + Zustand
- **AI Integration:** Multi-provider support (OpenAI, Gemini, Perplexity, Fallback)
- **Infrastructure:** Azure App Service + PostgreSQL + Key Vault (Bicep IaC)
- **Architecture:** Clean/Hexagonal with domain-driven design

---

## 🚀 Quick Start

### Prerequisites

- Python 3.12+, Node.js 20+, Git
- Azure subscription (for cloud deployment)

### Local Development

**Option 1: VS Code Tasks (Recommended)**

1. Open project in VS Code
2. **Ctrl+Shift+P** → "Tasks: Run Task"
3. Run: **Install All Dependencies** → **Start Backend Server** → **Start Frontend Dev Server**

**Option 2: Manual Setup**

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

### Cost-Optimized Architecture

- **Monthly Cost:** ~$43/month (Basic App Service + PostgreSQL + Key Vault)
- **Single Environment:** Direct production deployment for cost efficiency
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
