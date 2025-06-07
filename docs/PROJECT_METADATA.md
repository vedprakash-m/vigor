# PROJECT_METADATA.md

## 1. Project Overview
### 1.1 Purpose
Vigor is an AI-powered fitness and wellness companion designed to provide personalized, intelligent coaching and support for users' health journeys. The platform combines artificial intelligence, computer vision, and behavioral science to deliver a proactive, motivating, and comprehensive fitness experience.

**MVP Focus**: Secure user onboarding, personalized workout plan generation, workout logging with progress tracking, and AI-powered motivational coaching.

### 1.2 Stakeholders
- **End Users**: Fitness enthusiasts of all levels seeking personalized workout plans and AI-powered coaching
- **Administrators**: System administrators managing user tiers, LLM providers, and platform operations
- **Developers**: Full-stack development team maintaining and extending the platform
- **Business**: Product team tracking user engagement, satisfaction, and retention metrics

### 1.3 High-Level Goals & Success Metrics

#### User Satisfaction & Engagement
- **User Satisfaction**: Achieve 90% user satisfaction with workout plan personalization
- **User Retention**: Maintain 80% user retention through the first month
- **Weekly Engagement**: 70% of users log at least 3 workouts per week
- **AI Interaction**: 60% of users interact with the AI coach weekly
- **Session Duration**: Average session duration of 5+ minutes
- **User Rating**: 4.5+ star average rating with 75% recommending to friends

#### Technical Performance
- **System Uptime**: 99.9% uptime requirement
- **API Performance**: Response times under 200ms
- **AI Response Speed**: Successful workout plan generation in under 3 seconds
- **Security Compliance**: 100% GDPR compliance and data security
- **User Satisfaction**: 80% report plan personalization as "good" or better

#### Business Metrics
- **Growth**: 30% month-over-month user growth target
- **Retention**: 40% user retention after 30 days minimum
- **Security Confidence**: Less than 1% of users report security concerns
- **Plan Effectiveness**: Users report plan personalization as effective

### 1.4 Development Phases
- **Phase 1 (MVP)**: Secure onboarding, AI workout planning, logging, motivational coaching
- **Phase 2**: Computer vision form analysis, wearables integration, adaptive recovery
- **Phase 3**: Habit building, voice guidance, mood tracking, community features

## 2. System Architecture
### 2.1 Overview & Diagram
```mermaid
graph TB
    subgraph "Frontend Layer"
        UI[React/TypeScript SPA]
        Auth[Authentication Context]
        Pages[Page Components]
    end

    subgraph "Backend API Layer"
        API[FastAPI Application]
        Routes[API Routes]
        Services[Business Services]
    end

    subgraph "Core Services"
        LLM[LLM Orchestration]
        Admin[Admin Management]
        Security[Security & Auth]
    end

    subgraph "Data Layer"
        DB[(SQLite Database)]
        Models[SQLAlchemy Models]
    end

    subgraph "External Services"
        OpenAI[OpenAI API]
        Providers[Other LLM Providers]
    end

    UI --> API
    API --> Services
    Services --> Core Services
    Core Services --> Models
    Models --> DB
    LLM --> Providers
```

### 2.2 Technology Stack
**Frontend:**
- React 18 with TypeScript
- Vite (build tool)
- Tailwind CSS (styling)
- Jest + React Testing Library (testing)

**Backend:**
- Python 3.9+
- FastAPI (web framework)
- SQLAlchemy (ORM)
- Alembic (database migrations)
- SQLite (database)
- Pydantic (data validation)

**DevOps & Infrastructure:**
- Docker (containerization)
- GitHub Actions (CI/CD)
- Terraform (infrastructure as code)
- Pre-commit hooks (code quality)

**AI/ML:**
- OpenAI API integration
- Custom LLM orchestration layer
- Fallback provider system

### 2.3 Core Components & Interactions
- **Frontend SPA**: User interface for workout management, AI coaching, and account management
- **API Gateway**: FastAPI-based REST API handling all client requests
- **LLM Orchestration**: Smart routing and fallback system for AI provider management
- **Admin System**: Comprehensive admin panel for user/system management
- **Authentication**: JWT-based authentication with role-based access control

### 2.4 Data Model Overview
- **Users**: Core user accounts with tier-based permissions
- **Workouts**: Exercise routines and fitness plans
- **AI Interactions**: LLM conversation history and recommendations
- **Admin Data**: System configuration and administrative metadata

## 3. Key Features and Functionality

### 3.1 MVP Features (Phase 1)
- **Secure User Onboarding**: OAuth2/JWT authentication with comprehensive profile collection
- **Personalized Workout Planning**: LLM-generated workout plans based on goals, fitness level, equipment, and injuries
- **Comprehensive Workout Logging**: Track sets, reps, weight, RPE, duration with visual progress graphs
- **AI-Powered Coaching**: Daily motivational messages, Q&A system, workout-specific encouragement
- **User Profile Management**: Secure storage and management of fitness data and preferences
- **Admin Dashboard**: System management interface for user/tier/provider management

### 3.2 Phase 2 Features (Post-MVP)
- **Computer Vision Form Analysis**: Upload workout videos for AI-powered form feedback
- **Adaptive Recovery Readiness**: HRV + RPE + sleep data for workout modification suggestions
- **Wearables Integration**: Apple Health, Garmin, Google Fit data integration
- **Learning Hub**: Curated fitness education content personalized to user behavior

### 3.3 Phase 3 Features (Future Vision)
- **Habit Building System**: Track hydration, mobility, sleep with streak building and smart nudges
- **Voice-Guided Workouts**: AI-narrated workouts with multiple coach personality options
- **Mood & Energy Tracking**: Check-ins that influence coaching tone and workout intensity
- **Smart Calendar Integration**: Automatic workout scheduling based on calendar availability
- **Community Features**: Group challenges, social accountability, progress sharing
- **AI Reflections**: Post-workout journaling with trend detection and insights

### 3.4 Core System Features
- **User Tier Management**: Multi-level subscription system (Basic, Premium, Enterprise)
- **LLM Provider Management**: Dynamic AI provider switching and fallback handling
- **Secure Authentication**: JWT-based auth with role-based access control

## 4. Design Principles
- **Security by Design**: All user data encrypted, secure authentication, input validation
- **Scalability**: Modular architecture supporting horizontal scaling
- **Maintainability**: Clean code practices, comprehensive testing, documentation
- **Performance**: Optimized database queries, caching strategies, lazy loading
- **Reliability**: Fallback systems, error handling, graceful degradation
- **User Experience**: Responsive design, intuitive UI, fast load times

## 5. Known Constraints, Assumptions, and Design Decisions

### 5.1 Constraints
- **Database**: Currently using SQLite for simplicity; may need migration to PostgreSQL for production scaling
- **LLM Costs**: AI provider API costs must be managed through tier limitations
- **Single-tenant**: Current architecture is single-tenant; multi-tenancy not yet implemented
- **MVP Scope Limitations**: Several features explicitly excluded from MVP phase

### 5.2 Features Explicitly Out of Scope for MVP
- **Real-time Form Analysis**: Computer vision form feedback delayed to Phase 2
- **Wearable Device Integration**: Apple Health, Garmin integration in Phase 2
- **Social Features**: Community challenges and social accountability in Phase 3
- **Voice-Guided Workouts**: AI narrated workouts scheduled for Phase 3
- **Calendar Integration**: Smart scheduling features in Phase 3
- **Mobile App**: Initial focus on responsive web platform only
- **Nutrition Tracking**: Meal planning and nutrition features not planned
- **Live Video Coaching**: Real-time video sessions not in roadmap

### 5.2 Assumptions
- Users have stable internet connectivity for AI features
- LLM providers maintain reasonable API availability and response times
- User data volume will grow predictably with user base expansion

### 5.3 Design Decisions & Rationale
- **FastAPI over Django**: Chosen for better async support, automatic API documentation, and modern Python features
- **SQLite for MVP**: Rapid development and deployment; plan migration path to PostgreSQL for production
- **React SPA**: Modern, responsive user experience with component reusability and TypeScript support
- **JWT Authentication**: Stateless authentication supporting horizontal scalability
- **LLM Orchestration Layer**: Custom abstraction to support multiple AI providers and cost management
- **Tier-Based Architecture**: Enables freemium business model with clear upgrade paths
- **Computer Vision Delayed**: Phase 2 implementation allows MVP focus on core features
- **Web-First Approach**: Responsive web app before mobile to validate product-market fit

## 6. Core Modules/Services and Responsibilities

### 6.1 Backend Modules
- **`api/routes/`**: REST API endpoint definitions
  - `auth.py`: Authentication and authorization endpoints
  - `ai.py`: AI/LLM interaction endpoints
  - `workouts.py`: Workout management endpoints
  - `users.py`: User profile management
  - `admin.py`: Administrative functions
  - `llm_orchestration.py`: LLM provider management

- **`api/services/`**: Business logic implementation
  - `auth.py`: Authentication service logic
  - `ai.py`: AI interaction orchestration
  - `usage_tracking.py`: User activity and billing tracking

- **`core/`**: Core system functionality
  - `llm_orchestration/`: LLM provider management and routing
  - `admin_llm_manager.py`: Administrative LLM operations
  - `security.py`: Security utilities and helpers
  - `config.py`: Application configuration management

- **`database/`**: Data layer
  - `models.py`: SQLAlchemy ORM models
  - `connection.py`: Database connection management
  - `init_db.py`: Database initialization and seeding

### 6.2 Frontend Modules
- **`components/`**: Reusable UI components
- **`pages/`**: Route-based page components
- **`contexts/`**: React context providers (auth, theme, etc.)
- **`services/`**: API client and external service integrations
- **`types/`**: TypeScript type definitions

## 7. Key APIs and Data Contracts

### 7.1 Authentication APIs
- `POST /auth/login`: User authentication
- `POST /auth/register`: User registration
- `POST /auth/refresh`: Token refresh
- `POST /auth/logout`: User logout

### 7.2 AI/LLM APIs
- `POST /ai/chat`: AI conversation endpoint
- `GET /ai/recommendations`: Get personalized recommendations
- `POST /ai/workout-analysis`: Analyze workout performance

### 7.3 User Management APIs
- `GET /users/profile`: Retrieve user profile
- `PUT /users/profile`: Update user profile
- `GET /users/tier`: Get user subscription tier
- `PUT /users/tier`: Update user tier (admin only)

### 7.4 Workout APIs
- `GET /workouts/`: List user workouts
- `POST /workouts/`: Create new workout
- `PUT /workouts/{id}`: Update workout
- `DELETE /workouts/{id}`: Delete workout
- `POST /workouts/{id}/log`: Log workout session with sets/reps/RPE
- `GET /workouts/progress`: Get user progress analytics and visualizations
- `GET /workouts/plans`: Get personalized workout plan recommendations

### 7.5 Admin APIs
- `GET /admin/users`: List all users
- `GET /admin/system-status`: System health metrics
- `POST /admin/llm-providers`: Configure LLM providers
- `GET /admin/analytics`: System-wide usage analytics
- `PUT /admin/users/{id}/tier`: Update user tier
- `GET /admin/costs`: LLM usage and cost tracking

### 7.6 Progress Tracking APIs
- `GET /progress/stats`: User fitness statistics and milestones
- `GET /progress/charts`: Data for progress visualization charts
- `POST /progress/goals`: Set or update fitness goals
- `GET /progress/achievements`: User achievement history

## 8. Critical Business Logic Summary

### 8.1 User Profile & Personalization
- **Profile Data Collection**: Fitness goals, current fitness level, available equipment, injury history, exercise preferences
- **Workout Plan Generation**: LLM-powered personalized workout plans with clear explanations for exercise selections
- **Plan Adaptation**: Dynamic adjustment based on user feedback and progress tracking
- **Equipment Consideration**: Plans adapt to user's available equipment and physical limitations

### 8.2 Workout Logging & Progress Tracking
- **Comprehensive Logging**: Sets, reps, weight, Rate of Perceived Exertion (RPE), workout duration
- **Visual Progress**: Graphs, milestones, and historical workout data visualization
- **Workout History**: Complete tracking of user's fitness journey over time
- **Progress Milestones**: Automatic detection and celebration of user achievements

### 8.3 AI Coaching & Motivation
- **Daily Motivational Messages**: Personalized encouragement based on user progress and goals
- **Q&A System**: "Ask your coach" functionality answering fitness questions in plain language
- **Workout-Specific Encouragement**: Contextual motivation during exercise sessions
- **Educational Content**: Fitness concept explanations and myth-busting

### 8.4 User Tier Management
- **Tier Validation**: All feature access checked against user tier permissions
- **Usage Limits**: AI interactions limited by tier (Basic: 10/day, Premium: 100/day, Enterprise: unlimited)
- **Billing Integration**: Tier changes trigger billing system updates

### 8.5 LLM Orchestration Logic
- **Provider Selection**: Primary provider with automatic fallback to secondary providers
- **Rate Limiting**: Per-user and system-wide rate limiting for cost control
- **Context Management**: Conversation context maintained across AI interactions

### 8.6 Security Logic
- **JWT Validation**: All protected endpoints validate JWT tokens
- **Role-Based Access**: Admin endpoints require elevated permissions
- **Data Encryption**: Sensitive user data encrypted at rest and in transit
- **GDPR Compliance**: Full compliance with data protection regulations

## 9. Glossary of Terms / Domain Concepts

- **Tier**: User subscription level determining feature access and limits
- **LLM Orchestration**: System for managing multiple AI provider integrations
- **Workout Plan**: Structured exercise routine with sets, reps, and progression
- **AI Coach**: LLM-powered virtual fitness coach providing recommendations
- **RPE (Rate of Perceived Exertion)**: 1-10 scale measuring workout intensity perception
- **HRV (Heart Rate Variability)**: Biometric used for recovery readiness assessment
- **Fallback Provider**: Secondary AI provider used when primary provider fails
- **Usage Tracking**: Monitoring user activity for billing and tier enforcement
- **Form Analysis**: Computer vision-based assessment of exercise technique
- **Recovery Readiness**: Algorithm combining multiple factors to suggest rest vs. training
- **Micro-Workouts**: Short 5-10 minute exercise sessions for busy schedules
- **Smart Nudges**: Behavioral prompts designed to encourage healthy habits

## 10. Current Risks and Technical Debt

### 10.1 Technical Debt
- **Database Migration**: SQLite limitations for production scaling - need PostgreSQL migration strategy
- **Test Coverage**: Frontend test coverage needs improvement
- **Error Handling**: Inconsistent error handling patterns across modules
- **Documentation**: API documentation needs completion with request/response examples

### 10.2 Security Requirements & Risks
- **API Rate Limiting**: Need more robust rate limiting implementation per PRD requirements
- **Input Validation**: Enhanced validation for all user inputs required
- **Audit Logging**: Comprehensive audit trail for admin actions needed
- **XSS Protection**: Cross-site scripting prevention measures
- **End-to-End Encryption**: All sensitive data must be encrypted in transit and at rest

### 10.3 Scalability Concerns
- **Database Performance**: Query optimization needed for large datasets
- **File Storage**: Local file storage needs cloud migration strategy
- **Caching**: Redis or similar caching layer needed for performance
- **LLM Cost Management**: Need robust cost controls for AI provider usage

### 10.4 Open Product Questions (from PRD)
- **AI Response Latency**: What is the maximum acceptable latency for AI responses to user questions?
- **Feedback Mechanism**: Should we implement a feedback mechanism for workout plan effectiveness?
- **Exercise Database**: What is the minimum viable set of exercises to include in the initial database?
- **Multiple Goals**: How should we handle users with multiple concurrent fitness goals?
- **Message Frequency**: What is the appropriate frequency for AI check-ins and motivational messages?

## 11. Metadata Evolution Log

### Recent Updates
- **2024-12-XX**: Initial metadata creation with comprehensive project analysis
- **2025-06-06**: Enhanced metadata with PRD specifications and detailed feature breakdown
- **2025-06-06**: Added success metrics, open questions, and out-of-scope features
- **2025-06-06**: Integrated Phase 2 and Phase 3 roadmap details from project documentation

### Completed Documentation
- ✅ Project overview and stakeholder identification
- ✅ System architecture with mermaid diagram
- ✅ Technology stack specification
- ✅ Phase-based feature breakdown (MVP, Phase 2, Phase 3)
- ✅ Success metrics and KPIs
- ✅ Business logic documentation
- ✅ API endpoint specifications
- ✅ Risk assessment and technical debt analysis
- ✅ Domain terminology glossary

### TODOs
- [ ] Complete API endpoint documentation with request/response examples
- [ ] Document database schema with relationships diagram
- [ ] Add deployment architecture documentation
- [ ] Create troubleshooting guide for common issues
- [ ] Document LLM provider integration patterns
- [ ] Add user journey flow documentation
- [ ] Document error handling patterns and standards
- [ ] Create performance benchmarking guidelines

---

## Change Proposal Template

### Proposed Change:
_Describe the proposed modification_

### Rationale:
_Explain why this change is needed_

### Affected Modules/Sections:
_List impacted components_

### Impact on Metadata:
- [ ] Update Required
- [ ] No Change Needed

### Suggested Metadata Updates:
_Specific sections requiring updates_
