# 🏋️‍♂️ Vigor - AI-Powered Fitness Coaching Platform

> **Transform your fitness journey with personalized AI coaching, smart workout generation, and intelligent progress tracking.**

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![React 18](https://img.shields.io/badge/react-18+-blue.svg)](https://reactjs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com/)

## ✨ What is Vigor?

Vigor is a modern fitness platform that brings AI coaching to everyone. Get personalized workout plans, real-time advice, and progress tracking - all powered by intelligent AI that adapts to your fitness level, goals, and available equipment.

**Key Features:**

- 🤖 **Personal AI Coach** - Chat with your fitness coach anytime
- 📋 **Smart Workout Plans** - AI-generated workouts tailored to you
- 💰 **Flexible Pricing** - Free tier with 100 AI requests/month
- 📱 **Mobile-First** - Responsive design, works everywhere
- 🔧 **Multi-LLM Support** - Choose from OpenAI, Gemini, or Perplexity

## 🚀 Quick Start

### Try It Out

**Local Demo:** Follow the "Run Locally" steps below for a full-featured demo.

### Run Locally

```bash
# Clone and start backend
git clone https://github.com/vedprakash-m/vigor.git
cd vigor/backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt && python main.py

# Start frontend (new terminal)
cd ../frontend && npm install && npm run dev
```

**Access:** http://localhost:5173 | **Login:** admin@vigor.com / admin123!

### VS Code Development

1. Open project in VS Code
2. Run Task: "Install All Dependencies"
3. Run Task: "Start Backend Server" + "Start Frontend Dev Server"

## 🏗️ Architecture Overview

```mermaid
flowchart TD
  subgraph Frontend
    A[React 18 + Vite] --> B[Zustand Store]
    B --> C[REST API]
  end

  subgraph Backend (FastAPI)
    C --> D[LLM Gateway Facade]
    D --> E[Redis Cache]
    D --> F[Celery Worker]
    D --> G[PostgreSQL]
  end

  F -->|Health-checks| D
  D -->|Traces| H(OpenTelemetry Collector)
```

_Clean / Hexagonal_ architecture with repository and adapter layers ensures testability and maintainability.

## ⚡ One-Command Local Dev

```bash
# Dev containers recommended
make dev-up  # spins postgres, redis, backend & frontend via docker-compose
```

Services:

- http://localhost:8001 – FastAPI docs
- http://localhost:5173 – React app
- http://localhost:6006 – Storybook

## 📦 Production Build (Single Slot)

```bash
make build-images   # multi-stage Dockerfiles
az webapp up --name vigor-prod --resource-group vigor-rg --sku B1 --runtime "PYTHON|3.11"
```

CI/CD via GitHub Actions runs lint, tests, security scan, builds images and deploys to the single production slot.

## 🛡️ Quality Gates

- Ruff, Black, ESLint, Prettier
- MyPy strict + TypeScript strict
- Pytest/Jest coverage ≥ 80 % enforced in CI
- Bandit, Safety, licence scanning (FOSSA)

## 🌐 Live Demo

_Coming soon – follow progress in `docs/metadata.md`_

## 🏗️ Technology Stack

- **Backend:** FastAPI + Python + PostgreSQL
- **Frontend:** React 18 + TypeScript + Chakra UI
- **AI:** Multi-provider (OpenAI, Gemini, Perplexity)
- **Deployment:** Azure + Bicep (Infrastructure as Code)

## 🚀 Deploy to Production

```bash
./scripts/setup-production-secrets.sh
cd infrastructure/bicep && ./deploy.sh
git push origin main  # Triggers auto-deployment
```

Deploys to Azure with FREE tier App Service, PostgreSQL database, and monitoring.

## 📚 Documentation

- **[Getting Started](docs/getting-started.md)** - Complete setup guide
- **[Deployment](docs/deployment.md)** - Production deployment
- **[Architecture](docs/architecture.md)** - Technical deep dive
- **[API Docs](http://localhost:8001/docs)** - Interactive API reference
- **[Contributing](docs/CONTRIBUTING.md)** - How to contribute

## 🤝 Contributing

We welcome contributions! Report bugs, suggest features, or submit code improvements.

- **Issues:** [Report bugs or request features](https://github.com/vedprakash-m/vigor/issues)
- **Discussions:** [Community discussions](https://github.com/vedprakash-m/vigor/discussions)

## 📄 License

Licensed under **GNU Affero General Public License v3.0 (AGPLv3)**

- ✅ Free to use, modify, and distribute
- ✅ Commercial use allowed
- ⚠️ Source code must be disclosed when distributed

---

<div align="center">

**Built with ❤️ for the fitness community**

[⭐ Star us on GitHub](https://github.com/vedprakash-m/vigor) • [🐛 Report Bug](https://github.com/vedprakash-m/vigor/issues) • [💡 Request Feature](https://github.com/vedprakash-m/vigor/issues)

**Transform your fitness journey today!**

</div>
