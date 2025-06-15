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

### Docker Development

```bash
# Start all services with Docker Compose
docker-compose up -d

# Access services:
# - Backend: http://localhost:8000
# - Frontend: http://localhost:5173
# - Database: localhost:5432
```

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
```

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
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines

- Follow [Conventional Commits](https://conventionalcommits.org/) for commit messages
- Ensure test coverage ≥ 80% for new code
- Update ADR documentation for architectural changes
- Use pre-commit hooks to maintain code quality

## 📄 License

Licensed under **GNU Affero General Public License v3.0 (AGPLv3)**

- ✅ Free to use, modify, and distribute
- ✅ Commercial use allowed
- ⚠️ Source code must be disclosed when distributed

See [LICENSE](LICENSE) for full details.

---

<div align="center">

**Built with ❤️ for the fitness community**

[⭐ Star us on GitHub](https://github.com/vedprakash-m/vigor) • [🐛 Report Bug](https://github.com/vedprakash-m/vigor/issues) • [💡 Request Feature](https://github.com/vedprakash-m/vigor/issues)

**Transform your fitness journey today!**

</div>
