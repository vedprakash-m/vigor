# Vigor Deployment Guide

## 🚀 Complete Setup Guide for Vigor Fitness App on Azure

This guide will walk you through deploying the Vigor fitness app to Azure using Infrastructure as Code (Terraform) and GitHub Actions CI/CD.

## 📋 Prere# List all resources

az resource list --resource-group vigor-rg --output table

# Access Application Insights

az monitor app-insights show --resource-group vigor-rg --app vigor-production-aites

### Required Tools

- **Git** (latest version)
- **Azure CLI** (latest version)
- **Terraform** (>= 1.0)
- **GitHub Account** with admin access
- **Azure Subscription** with contributor access

### Required API Keys

- **OpenAI API Key** (optional but recommended)
- **Google Gemini API Key** (recommended for cost efficiency)
- **Perplexity API Key** (optional)

## 🏗️ Step 1: Create GitHub Repository

### 1.1 Create Repository

```bash
# Go to GitHub.com and create a new repository named "vigor"
# Or use GitHub CLI:
gh repo create vigor --public --description "AI-powered fitness app with admin controls"
```

### 1.2 Clone and Setup Local Repository

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/vigor.git
cd vigor

# Copy all the Vigor project files to this directory
# (Make sure all the files from your current vigor project are copied here)

# Initialize git (if not already done)
git init
git add .
git commit -m "Initial commit: Vigor fitness app with Azure IaC"
git branch -M main
git push -u origin main
```

## 🔐 Step 2: Setup Azure Prerequisites

### 2.1 Create Azure Service Principal

```bash
# Login to Azure
az login

# Create service principal for GitHub Actions
az ad sp create-for-rbac --name "vigor-github-actions" --role contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
  --sdk-auth

# Save the output - you'll need it for GitHub secrets
```

### 2.2 Create Terraform State Storage

```bash
# Create resource group for Terraform state
az group create --name vigor-rg --location "East US"

# Create storage account for Terraform state
STORAGE_ACCOUNT_NAME="vigortfstate$(date +%s)"
az storage account create \
  --resource-group vigor-rg \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob

# Create container for state files
az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT_NAME

echo "Terraform state storage account: $STORAGE_ACCOUNT_NAME"
```

## 🔑 Step 3: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and Variables → Actions → New repository secret

### Required Secrets:

#### Azure Configuration

```
AZURE_CREDENTIALS
# Paste the entire JSON output from the service principal creation

TFSTATE_RESOURCE_GROUP
# Value: vigor-rg

TFSTATE_STORAGE_ACCOUNT
# Value: your storage account name from step 2.2
```

#### Database & Security

```
POSTGRES_ADMIN_PASSWORD
# Value: A secure password (min 8 chars, include uppercase, lowercase, numbers)

SECRET_KEY
# Value: A random 32+ character string for JWT tokens
```

#### AI Provider API Keys

```
OPENAI_API_KEY
# Value: Your OpenAI API key (optional)

GEMINI_API_KEY
# Value: Your Google Gemini API key (recommended)

PERPLEXITY_API_KEY
# Value: Your Perplexity API key (optional)
```

#### Admin Configuration

```
ADMIN_EMAIL
# Value: Your admin email address
```

### Generate Secure Values:

```bash
# Generate secure password for PostgreSQL
openssl rand -base64 32

# Generate secret key for JWT
openssl rand -base64 48
```

## 🏭 Step 4: Deploy Infrastructure

### 4.1 Deploy Development Environment

```bash
# Push code to trigger GitHub Actions
git add .
git commit -m "Setup infrastructure and CI/CD"
git push origin main

# Or manually trigger deployment
# Go to GitHub → Actions → Vigor CI/CD Pipeline → Run workflow
# Select environment: dev
```

### 4.2 Monitor Deployment

1. Go to **GitHub Actions** tab in your repository
2. Watch the **Vigor CI/CD Pipeline** workflow
3. Check each step: Security → Backend → Frontend → Terraform → Deploy

### 4.3 Verify Deployment

After successful deployment, check the workflow output for:

- **Backend URL**: `https://vigor-dev-app-xxxxxxxx-backend.azurewebsites.net`
- **Frontend URL**: `https://vigor-dev-app-xxxxxxxx-frontend.azurestaticapps.net`

## 🔧 Step 5: Local Development Setup

### 5.1 Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cat > .env << EOF
SECRET_KEY=your-local-secret-key
DATABASE_URL=sqlite:///./vigor.db
LLM_PROVIDER=fallback
OPENAI_API_KEY=your-openai-key
GEMINI_API_KEY=your-gemini-key
PERPLEXITY_API_KEY=your-perplexity-key
ADMIN_EMAIL=admin@vigor-fitness.com
EOF

# Run database migrations
alembic upgrade head

# Start backend server
uvicorn main:app --reload
```

### 5.2 Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Create .env file
cat > .env << EOF
VITE_API_URL=http://localhost:8000
EOF

# Start frontend server
npm run dev
```

## 🌐 Step 6: Production Deployment

### 6.1 Create Production Branch

```bash
# Create and push main branch for production
git checkout -b main
git push origin main
```

### 6.2 Configure Production Secrets

Add production-specific secrets in GitHub:

```
# Update these for production values
POSTGRES_ADMIN_PASSWORD_PROD
SECRET_KEY_PROD
ADMIN_EMAIL_PROD
```

### 6.3 Deploy to Production

```bash
# Push to main branch triggers production deployment
git push origin main

# Or manually trigger:
# GitHub → Actions → Run workflow → Select "production"
```

## 📊 Step 7: Monitor and Manage

### 7.1 Access Azure Resources

```bash
# List all resources
az resource list --resource-group vigor-production-rg --output table

# Access Application Insights
az monitor app-insights show --resource-group vigor-production-rg --app vigor-production-ai
```

### 7.2 Admin Dashboard Access

1. Register a user with username containing "admin" (e.g., "admin123")
2. Login to the app
3. Navigate to `/admin` to access the admin dashboard
4. Configure AI provider priorities and budgets

### 7.3 Monitor Costs

```bash
# Check Azure costs
az consumption usage list --start-date "2024-01-01" --end-date "2024-01-31"

# Or use Azure Cost Management in the portal
```

## 🔍 Step 8: Testing and Verification

### 8.1 Health Checks

```bash
# Backend health check
curl https://your-backend-url.azurewebsites.net/health

# Frontend accessibility
curl https://your-frontend-url.azurestaticapps.net

# API functionality
curl -X POST https://your-backend-url.azurewebsites.net/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"testpass123"}'
```

### 8.2 Admin Features Test

1. **AI Provider Management**: Test switching between providers
2. **Budget Controls**: Set spending limits and verify enforcement
3. **Usage Analytics**: Check real-time metrics
4. **Cost Optimization**: Test automated provider switching

## 🚨 Troubleshooting

### Common Issues

#### 1. Terraform State Lock

```bash
# If Terraform state is locked
az storage blob lease break --container-name tfstate --blob-name vigor-dev.terraform.tfstate --account-name YOUR_STORAGE_ACCOUNT
```

#### 2. GitHub Actions Failing

- Check secrets are correctly set
- Verify Azure credentials have correct permissions
- Check Terraform syntax with `terraform validate`

#### 3. App Service Deployment Issues

```bash
# Check App Service logs
az webapp log tail --name your-app-name --resource-group your-rg-name
```

#### 4. Database Connection Issues

- Verify PostgreSQL firewall rules
- Check connection string format
- Ensure database is running

### Debug Commands

```bash
# Check backend logs
az webapp log download --name vigor-dev-app-xxxxxxxx-backend --resource-group vigor-rg

# Check container registry
az acr repository list --name vigordevacr

# Test database connection
psql "postgresql://username:password@server:5432/database?sslmode=require"
```

## 📈 Cost Optimization Tips

### Development Environment

- **Estimated Cost**: $45-65/month
- **Optimization**: Use B1 App Service plan, basic Redis cache

### Production Environment

- **Estimated Cost**: $180-220/month
- **Optimization**: Enable autoscaling, use reserved instances

### AI Provider Cost Management

- **Gemini Flash**: Most cost-effective for high volume
- **GPT-4o-mini**: Good balance of cost and quality
- **Smart routing**: Use cheaper providers during peak hours

## 🔄 Maintenance and Updates

### Regular Tasks

1. **Monitor costs** weekly using Azure Cost Management
2. **Update dependencies** monthly
3. **Review AI usage patterns** and optimize provider priorities
4. **Backup database** (automated, but verify)
5. **Security updates** via Dependabot

### Scaling Guidelines

- **Users < 1,000**: Dev configuration sufficient
- **Users 1,000-10,000**: Upgrade to S1 App Service plan
- **Users > 10,000**: Use P1v3 with autoscaling enabled

## 📞 Support and Resources

### Documentation

- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Monitoring URLs

- **Azure Portal**: https://portal.azure.com
- **Application Insights**: Check your resource group
- **GitHub Actions**: https://github.com/YOUR_USERNAME/vigor/actions

---

## ✅ Deployment Checklist

### Pre-Deployment

- [ ] GitHub repository created and code pushed
- [ ] Azure subscription active
- [ ] All GitHub secrets configured
- [ ] Terraform state storage created
- [ ] API keys obtained

### Post-Deployment

- [ ] Health checks passing
- [ ] Admin dashboard accessible
- [ ] AI providers configured
- [ ] Budget limits set
- [ ] Monitoring alerts configured
- [ ] SSL certificates active
- [ ] Domain name configured (optional)

### Production Readiness

- [ ] Load testing completed
- [ ] Backup strategy verified
- [ ] Disaster recovery plan documented
- [ ] Security review completed
- [ ] Performance optimization applied

---

**🎉 Congratulations!** Your Vigor fitness app is now deployed on Azure with enterprise-grade infrastructure, AI provider management, and cost optimization features!
