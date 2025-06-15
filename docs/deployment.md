# Production Deployment Guide

This guide covers deploying Vigor to production environments.

## Azure Deployment (Recommended)

### Quick Deploy

Deploy to Azure with one command:

```bash
# Set up secrets and deploy infrastructure
./scripts/setup-production-secrets.sh
cd infrastructure/bicep && ./deploy.sh
git push origin main  # Triggers automatic deployment
```

### What Gets Deployed

| Resource                 | SKU      | Purpose                    |
| ------------------------ | -------- | -------------------------- |
| **App Service**          | F1 Free  | Backend API (FastAPI)      |
| **Static Web App**       | Standard | Frontend (React + Vite)    |
| **PostgreSQL**           | B1ms     | Database with 10GB storage |
| **Key Vault**            | Standard | Secure secret management   |
| **Application Insights** | -        | Performance monitoring     |

### Infrastructure Features

- **🏗️ Azure Bicep**: Modern Infrastructure as Code
- **🔐 OIDC Authentication**: Secure GitHub Actions deployment
- **🌍 Single Region**: Central US for cost efficiency
- **💰 Cost Optimized**: FREE tier hosting + minimal database costs
- **📊 Full Monitoring**: Application Insights + Log Analytics
- **🔒 Enterprise Security**: Azure Key Vault + managed identities

### Required Secrets

#### Core Secrets (Required)

```bash
# Database
POSTGRES_ADMIN_PASSWORD=your-secure-db-password

# Application Security
SECRET_KEY=your-jwt-signing-key-32chars-min
ADMIN_EMAIL=admin@your-domain.com

# Azure Authentication (auto-configured)
AZURE_CLIENT_ID=42aae4cc-5dd0-4469-9f10-87e45dc45088
AZURE_TENANT_ID=80fe68b7-105c-4fb9-ab03-c9a818e35848
AZURE_SUBSCRIPTION_ID=8c48242c-a20e-448a-ac0f-be75ac5ebad0
```

#### Optional Secrets (AI Features)

```bash
# AI Providers (cost-optimized order)
GEMINI_API_KEY=your-gemini-key       # Primary (cost-effective)
PERPLEXITY_API_KEY=your-perplexity-key  # Secondary (balanced)
OPENAI_API_KEY=your-openai-key       # Premium (advanced features)
```

### Deployment Process

1. **Prerequisites**

   - Azure subscription
   - GitHub repository
   - Azure CLI installed

2. **Setup GitHub Secrets**

   ```bash
   ./scripts/setup-production-secrets.sh
   ```

3. **Deploy Infrastructure**

   ```bash
   cd infrastructure/bicep
   ./deploy.sh
   ```

4. **Trigger Application Deployment**

   ```bash
   git push origin main
   ```

5. **Verify Deployment**
   - Check GitHub Actions for successful deployment
   - Visit your app URL
   - Run health checks

## Alternative Deployment Options

### Docker Deployment

Build and run with Docker:

```bash
# Backend
cd backend
docker build -t vigor-backend .
docker run -p 8001:8001 vigor-backend

# Frontend
cd frontend
docker build -t vigor-frontend .
docker run -p 5173:5173 vigor-frontend
```

### Self-Hosting

Deploy on any VPS or on-premises server:

1. **Setup Server**

   - Ubuntu 20.04+ or similar
   - Python 3.9+, Node.js 18+
   - PostgreSQL 12+
   - Nginx (recommended)

2. **Deploy Application**

   ```bash
   # Clone and setup
   git clone https://github.com/vedprakash-m/vigor.git
   cd vigor

   # Backend
   cd backend
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   alembic upgrade head

   # Frontend
   cd ../frontend
   npm install
   npm run build

   # Setup systemd service (optional)
   sudo cp deployment/vigor-backend.service /etc/systemd/system/
   sudo systemctl enable vigor-backend
   sudo systemctl start vigor-backend
   ```

3. **Configure Nginx**
   ```nginx
   server {
       listen 80;
       server_name your-domain.com;

       location / {
           root /path/to/vigor/frontend/dist;
           try_files $uri $uri/ /index.html;
       }

       location /api {
           proxy_pass http://localhost:8001;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

## Environment Configuration

### Production Environment Variables

```bash
# Application
NODE_ENV=production
ENVIRONMENT=production
DEBUG=false

# Database
DATABASE_URL=postgresql://user:pass@host:5432/vigor

# Security
SECRET_KEY=your-secure-secret-key
CORS_ORIGINS=https://your-domain.com

# AI Providers
LLM_PROVIDER=gemini  # or openai, perplexity
GEMINI_API_KEY=your-key
OPENAI_API_KEY=your-key
PERPLEXITY_API_KEY=your-key

# Monitoring
ENABLE_ANALYTICS=true
LOG_LEVEL=INFO
```

## Monitoring and Maintenance

### Health Checks

Vigor includes built-in health check endpoints:

- `/health` - Basic health check
- `/health/database` - Database connectivity
- `/health/llm` - AI provider status

### Application Monitoring

Azure deployment includes:

- **Application Insights**: Performance monitoring
- **Log Analytics**: Centralized logging
- **Alerts**: Automated notifications for issues

### Backup Strategy

- **Database**: Automatic PostgreSQL backups (Azure)
- **Application**: Git-based source control
- **Configuration**: Infrastructure as Code (Bicep)

## Scaling

### Horizontal Scaling

- **App Service**: Auto-scaling based on CPU/memory
- **Database**: Read replicas for heavy read workloads
- **CDN**: Azure CDN for static assets

### Performance Optimization

- **Caching**: Redis for session management
- **Database**: Connection pooling and query optimization
- **Frontend**: Bundle optimization and lazy loading

## Security

### Security Features

- **Authentication**: JWT with secure refresh tokens
- **HTTPS**: TLS 1.2+ enforced
- **CORS**: Strict origin controls
- **Secrets**: Azure Key Vault integration
- **Scanning**: Automated security scans

### Security Checklist

- [ ] All secrets stored in Key Vault
- [ ] HTTPS enforced
- [ ] CORS properly configured
- [ ] Regular security updates
- [ ] Monitoring enabled
- [ ] Backup strategy implemented

## Troubleshooting

### Common Issues

1. **Deployment Fails**

   - Check GitHub Actions logs
   - Verify Azure credentials
   - Ensure quotas available

2. **App Won't Start**

   - Check environment variables
   - Verify database connectivity
   - Review Application Insights logs

3. **AI Features Not Working**
   - Check API key configuration
   - Verify provider status
   - Review usage limits

### Getting Help

- **[GitHub Issues](https://github.com/vedprakash-m/vigor/issues)** - Report deployment issues
- **[Documentation](../README.md)** - Browse all guides
- **[Azure Support](https://azure.microsoft.com/support/)** - Azure-specific issues
