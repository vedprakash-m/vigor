# 🏋️‍♂️ Vigor - AI-Powered Fitness Coaching Platform

> **Transform your fitness journey with personalized AI coaching, smart workout generation, and cost-optimized LLM integration.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
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
git clone https://github.com/your-username/vigor.git
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
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

---

## 💰 Cost Optimization Guide

### LLM Provider Comparison

| Provider | Cost (per 1M tokens) | Free Tier | Best For |
|----------|---------------------|-----------|----------|
| **Google Gemini** | $0.075 - $0.30 | ✅ Available | Development, Budget |
| **Perplexity** | $0.20 - $0.20 | ❌ Paid | Real-time data, Production |
| **OpenAI** | $0.50 - $1.50 | ❌ Paid | Advanced reasoning |

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

### Full API Documentation
Visit http://localhost:8000/docs for interactive API documentation.

---

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend │    │  FastAPI Backend │    │  AI Providers   │
│                 │    │                 │    │                 │
│ • Chakra UI     │◄───┤ • JWT Auth      │◄───┤ • OpenAI        │
│ • TypeScript    │    │ • SQLAlchemy    │    │ • Gemini        │
│ • PWA Ready     │    │ • LLM Abstraction│    │ • Perplexity    │
│ • Mobile-First  │    │ • RESTful API   │    │ • Fallback      │
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

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Commit with conventional commits: `git commit -m "feat: add amazing feature"`
5. Push to your fork: `git push origin feature/amazing-feature`
6. Open a Pull Request

### Code Standards
- **Backend**: Follow PEP 8, use type hints
- **Frontend**: Use TypeScript, follow React best practices
- **Tests**: Maintain >80% code coverage
- **Documentation**: Update README and API docs

---

## 📖 Additional Resources

### Documentation
- [LLM Provider Setup Guide](backend/LLM_SETUP.md)
- [API Reference](http://localhost:8000/docs)
- [Contributing Guidelines](CONTRIBUTING.md)

### Getting API Keys
- [Google Gemini (Free Tier)](https://makersuite.google.com/app/apikey)
- [Perplexity API](https://docs.perplexity.ai/)
- [OpenAI Platform](https://platform.openai.com/api-keys)

### Community
- [Discord Community](https://discord.gg/vigor-fitness) (coming soon)
- [GitHub Discussions](https://github.com/your-username/vigor/discussions)
- [Issue Tracker](https://github.com/your-username/vigor/issues)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **OpenAI**: For pioneering conversational AI
- **Google**: For Gemini's cost-effective AI capabilities
- **Perplexity**: For real-time AI with excellent value
- **FastAPI**: For the excellent Python web framework
- **React Team**: For the robust frontend framework
- **Chakra UI**: For the beautiful component library

---

## 📊 Project Status

**Current Version**: v1.0.0-beta  
**Status**: ✅ MVP Complete - Ready for beta testing  
**Next Release**: v1.1.0 - Enhanced AI features and mobile improvements

### Roadmap
- ✅ **Phase 1**: Core MVP with AI coaching
- 🔄 **Phase 2**: Computer vision form analysis
- 📋 **Phase 3**: Wearables integration
- 📋 **Phase 4**: Social features and challenges

---

<div align="center">

**Built with ❤️ for the fitness community**

[⭐ Star us on GitHub](https://github.com/your-username/vigor) • [🐛 Report Bug](https://github.com/your-username/vigor/issues) • [💡 Request Feature](https://github.com/your-username/vigor/issues)

</div>
