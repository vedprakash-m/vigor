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

## 🚀 Deployment

### Environment Variables

#### Required

```bash
SECRET_KEY=your-super-secret-key-for-jwt
DATABASE_URL=sqlite:///./vigor.db  # or PostgreSQL URL
```

#### Optional (AI Features)

```bash
LLM_PROVIDER=gemini
GEMINI_API_KEY=your-gemini-api-key
OPENAI_API_KEY=your-openai-api-key
PERPLEXITY_API_KEY=your-perplexity-api-key
```

### Production Deployment

1. **Backend**: Deploy FastAPI app to cloud provider (Heroku, AWS, Azure)
2. **Frontend**: Build and deploy to CDN (Vercel, Netlify, CloudFlare)
3. **Database**: Use managed PostgreSQL service
4. **AI**: Configure provider API keys via environment variables

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

**Current Version**: v1.0.0-beta  
**Status**: ✅ 90% Complete - User tier system implemented, ready for production  
**Next Release**: v1.1.0 - Frontend tier management UI and final production fixes

### Completed Features ✅

- **Backend Infrastructure**: FastAPI server with JWT authentication
- **Database System**: SQLite with Alembic migrations
- **User Tier System**: Free/Premium/Unlimited tiers with usage tracking
- **AI Integration**: Multi-provider LLM support (OpenAI, Gemini, Perplexity)
- **Usage Tracking**: Complete backend service for monitoring AI usage
- **API Documentation**: Comprehensive OpenAPI specification
- **Admin System**: Default admin user for system management

### In Progress 🔄

- **Tier Management UI**: Frontend components for tier upgrades and usage analytics
- **Service Integration**: Fixing import issues between usage tracking and AI services
- **Production Testing**: End-to-end testing of tier limitations and upgrades

### Roadmap 📋

- ✅ **Phase 1**: Core MVP with AI coaching (Complete)
- ✅ **Phase 2**: User tier system and usage tracking (Complete)
- 🔄 **Phase 3**: Frontend tier management UI (In Progress)
- 📋 **Phase 4**: Computer vision form analysis
- 📋 **Phase 5**: Wearables integration
- 📋 **Phase 6**: Social features and challenges

### Recent Updates (Latest)

- **User Tier Database**: Added `user_tier_limits` and `user_usage_limits` tables
- **Usage Tracking Service**: Comprehensive service for monitoring and limiting AI usage
- **Tier API Endpoints**: Backend routes for tier management and analytics
- **Database Migration**: Alembic migration `003_add_user_tiers` successfully applied
- **Model Enhancement**: Extended user profiles with tier and budget management

### Known Issues 🔧

- **Import Resolution**: `UsageTrackingService` import needs fixing in AI service
- **Tier Routes**: Temporarily disabled in main.py pending import fix
- **Frontend Integration**: Tier management UI components need implementation

---

<div align="center">

**Built with ❤️ for the fitness community**

[⭐ Star us on GitHub](https://github.com/vedprakash-m/vigor) • [🐛 Report Bug](https://github.com/vedprakash-m/vigor/issues) • [💡 Request Feature](https://github.com/vedprakash-m/vigor/issues)

</div>
