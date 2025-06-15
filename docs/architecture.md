# Architecture Overview

This document provides a comprehensive overview of Vigor's architecture, design decisions, and technical implementation.

## System Architecture

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
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Static Assets │    │   PostgreSQL    │    │  Azure Services │
│                 │    │                 │    │                 │
│ • Azure CDN     │    │ • User Data     │    │ • Key Vault     │
│ • Gzip/Brotli   │    │ • Tier Info     │    │ • App Insights  │
│ • Cache Headers │    │ • Usage Logs    │    │ • App Service   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Key Design Principles

### 1. Separation of Concerns

- **Frontend**: Pure UI layer focused on user experience
- **Backend**: Business logic, authentication, and data management
- **AI Layer**: Abstracted LLM integration with provider switching
- **Infrastructure**: Cloud-native deployment with IaC

### 2. Provider Agnostic

- **LLM Abstraction**: Seamless switching between AI providers
- **Database Flexibility**: SQLite for development, PostgreSQL for production
- **Cloud Neutral**: Can be deployed on any cloud provider or on-premises

### 3. Progressive Enhancement

- **Core Functionality**: Works without AI providers (fallback mode)
- **AI Enhancement**: Advanced features when AI is available
- **Offline Capability**: PWA features for offline access
- **Mobile-First**: Responsive design with mobile optimization

### 4. Cost-Conscious Design

- **Efficient Resource Usage**: Optimized queries and caching
- **Smart Provider Selection**: Cost-based LLM provider switching
- **Usage Tracking**: Built-in monitoring and tier management
- **Scalable Infrastructure**: Pay-as-you-grow architecture

## Frontend Architecture

### Technology Stack

- **React 18**: Component-based UI with hooks
- **TypeScript**: Type safety and better developer experience
- **Chakra UI v3**: Accessible component library
- **Vite**: Fast build tool and dev server
- **React Router**: Client-side routing
- **Context API**: State management

### Component Structure

```
src/
├── components/           # Reusable UI components
│   ├── auth/            # Authentication components
│   ├── chat/            # Chat interface components
│   ├── common/          # Shared components
│   └── tier/            # Tier management components
├── hooks/               # Custom React hooks
├── services/            # API service layer
├── types/               # TypeScript type definitions
├── utils/               # Utility functions
└── App.tsx             # Main application component
```

### State Management Strategy

- **React Context**: Global state (auth, user, theme)
- **Local State**: Component-specific state with useState
- **Server State**: React Query for API data management
- **Form State**: Controlled components with validation

## Backend Architecture

### Technology Stack

- **FastAPI**: Modern Python web framework
- **SQLAlchemy**: ORM with declarative models
- **Alembic**: Database migrations
- **Pydantic**: Data validation and serialization
- **JWT**: Authentication and authorization
- **PostgreSQL**: Production database

### Directory Structure

```
backend/
├── api/                 # API routes and endpoints
│   ├── routes/         # Route handlers
│   ├── schemas/        # Pydantic models
│   └── services/       # Business logic
├── core/               # Core functionality
│   ├── ai.py          # AI integration
│   ├── auth.py        # Authentication
│   └── config.py      # Configuration
├── database/           # Database layer
│   ├── models/        # SQLAlchemy models
│   └── connection.py  # Database connection
└── tests/             # Test suite
```

### API Design

- **RESTful Endpoints**: Standard HTTP methods and status codes
- **OpenAPI Schema**: Auto-generated documentation
- **Input Validation**: Pydantic models for request/response
- **Error Handling**: Consistent error responses
- **Rate Limiting**: Built-in request throttling

## AI Integration Layer

### Provider Abstraction

The AI integration is designed to be provider-agnostic:

```python
class LLMInterface(ABC):
    @abstractmethod
    async def generate_response(self, messages: List[Dict]) -> str:
        pass

    @abstractmethod
    def get_provider_name(self) -> str:
        pass
```

### Provider Implementations

- **OpenAI Provider**: GPT-3.5/GPT-4 integration
- **Gemini Provider**: Google Gemini models
- **Perplexity Provider**: Llama-based models
- **Fallback Provider**: Static responses for demos

### Cost Management

- **Usage Tracking**: Per-user request counting
- **Tier Enforcement**: Request limits based on user tier
- **Cost Monitoring**: Real-time cost tracking per provider
- **Smart Routing**: Automatic provider selection based on cost/quality

## Database Design

### Core Entities

```sql
-- Users and Authentication
users (id, email, password_hash, is_active, created_at)
user_profiles (user_id, name, fitness_level, goals, equipment)

-- Tier Management
user_tiers (id, name, max_requests, price)
user_tier_assignments (user_id, tier_id, assigned_at)

-- Usage Tracking
ai_usage_logs (id, user_id, provider, tokens_used, cost, timestamp)
tier_usage (user_id, period, requests_used, tier_id)

-- AI Configuration
ai_provider_priorities (id, provider_name, priority, is_active)
budget_settings (id, monthly_budget, alert_threshold)
```

### Migration Strategy

- **Alembic Migrations**: Version-controlled schema changes
- **Backward Compatibility**: Safe migration paths
- **Data Preservation**: No data loss during upgrades
- **Rollback Support**: Ability to revert migrations

## Security Architecture

### Authentication Flow

1. **User Registration**: Email/password with validation
2. **Login**: JWT token generation with refresh token
3. **Token Refresh**: Automatic token renewal
4. **Authorization**: Role-based access control

### Security Measures

- **Password Hashing**: bcrypt with salt
- **JWT Security**: Short-lived access tokens, secure refresh tokens
- **CORS Protection**: Strict origin controls
- **Input Validation**: SQL injection and XSS prevention
- **Rate Limiting**: Brute force protection

### Secret Management

- **Development**: Environment variables
- **Production**: Azure Key Vault integration
- **CI/CD**: GitHub Secrets with OIDC
- **Database**: Encrypted connections (SSL/TLS)

## Infrastructure Architecture

### Azure Resources

```
Resource Group: vigor-rg
├── App Service Plan (B1 Basic)
├── Web App (vigor-backend)
├── Static Web App (vigor-frontend)
├── PostgreSQL Flexible Server (B1ms)
├── Key Vault (vigor-keyvault)
├── Application Insights (vigor-insights)
└── Log Analytics Workspace
```

### Deployment Strategy

- **Infrastructure as Code**: Azure Bicep templates
- **CI/CD Pipeline**: GitHub Actions
- **Zero-Downtime Deployment**: Blue-green deployment strategy
- **Automated Testing**: Health checks and smoke tests

### Monitoring and Observability

- **Application Insights**: Performance monitoring
- **Health Checks**: Built-in endpoint monitoring
- **Logging**: Structured logging with correlation IDs
- **Alerting**: Automated notifications for issues

## Performance Considerations

### Frontend Optimization

- **Code Splitting**: Lazy loading of routes and components
- **Bundle Optimization**: Tree shaking and minification
- **Caching**: Service worker for offline capability
- **Image Optimization**: WebP format with fallbacks

### Backend Optimization

- **Database Optimization**: Indexed queries and connection pooling
- **Caching**: Redis for session management
- **Async Processing**: FastAPI's async capabilities
- **Resource Limits**: Memory and CPU optimization

### AI Provider Optimization

- **Request Batching**: Combining multiple requests
- **Response Caching**: Storing common responses
- **Provider Failover**: Automatic switching on failures
- **Token Optimization**: Efficient prompt engineering

## Scalability Strategy

### Horizontal Scaling

- **Stateless Design**: No server-side state storage
- **Load Balancing**: Multiple backend instances
- **Database Scaling**: Read replicas for heavy read workloads
- **CDN**: Global content distribution

### Vertical Scaling

- **Resource Monitoring**: CPU and memory usage tracking
- **Auto-scaling**: Automatic resource adjustment
- **Performance Tuning**: Query optimization and caching
- **Capacity Planning**: Proactive resource planning

## Quality Assurance

### Testing Strategy

- **Unit Tests**: Component and function testing
- **Integration Tests**: API endpoint testing
- **E2E Tests**: Full user journey testing
- **Performance Tests**: Load and stress testing

### Code Quality

- **Type Safety**: TypeScript for frontend, Pydantic for backend
- **Linting**: ESLint, Prettier, Black, isort
- **Pre-commit Hooks**: Automated code quality checks
- **Code Reviews**: Mandatory review process

### Continuous Integration

- **Automated Testing**: All tests run on every commit
- **Security Scanning**: Vulnerability detection
- **Dependency Auditing**: Package security monitoring
- **Quality Gates**: Minimum quality requirements

## Future Considerations

### Planned Improvements

- **Microservices**: Service decomposition for better scalability
- **Event-Driven Architecture**: Async processing with message queues
- **Advanced AI Features**: Image analysis and form correction
- **Mobile Apps**: Native iOS and Android applications

### Technical Debt

- **Legacy Code**: Gradual refactoring of older components
- **Documentation**: Comprehensive API and code documentation
- **Test Coverage**: Increasing test coverage to 90%+
- **Performance**: Ongoing optimization efforts

This architecture provides a solid foundation for a scalable, maintainable, and secure fitness coaching platform while maintaining flexibility for future enhancements.
