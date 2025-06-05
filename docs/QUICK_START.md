# Vigor Quick Start Guide

## 🚀 5-Minute Setup

### Step 1: Create GitHub Repository
```bash
# Make scripts executable
chmod +x scripts/setup-github-repo.sh
chmod +x scripts/generate-secrets.sh

# Run setup script (requires GitHub CLI)
./scripts/setup-github-repo.sh
```

### Step 2: Generate Secrets
```bash
# Generate secure passwords and keys
./scripts/generate-secrets.sh
```

### Step 3: Setup Azure
```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac --name "vigor-github-actions" --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --sdk-auth

# Create Terraform state storage
az group create --name vigor-tfstate-rg --location "East US"
STORAGE_ACCOUNT_NAME="vigortfstate$(date +%s)"
az storage account create \
  --resource-group vigor-tfstate-rg \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob
az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT_NAME
```

### Step 4: Configure GitHub Secrets
Go to your repository → Settings → Secrets and Variables → Actions

Add these secrets:
- `AZURE_CREDENTIALS` (from service principal output)
- `TFSTATE_RESOURCE_GROUP` = `vigor-tfstate-rg`
- `TFSTATE_STORAGE_ACCOUNT` = (your storage account name)
- `POSTGRES_ADMIN_PASSWORD` (from secrets script)
- `SECRET_KEY` (from secrets script)
- `ADMIN_EMAIL` (your email)
- `GEMINI_API_KEY` (optional but recommended)

### Step 5: Deploy
```bash
# Push to trigger deployment
git push origin main

# Or manually trigger via GitHub Actions web interface
```

## 🎯 What You Get

### Infrastructure
- **Azure App Service** for backend API
- **Azure Static Web App** for frontend
- **PostgreSQL** for database
- **Redis** for caching
- **Key Vault** for secrets
- **Application Insights** for monitoring

### Features
- **AI Provider Management** with cost optimization
- **Admin Dashboard** for real-time control
- **Budget Enforcement** to prevent overspending
- **Auto-failover** between AI providers
- **Enterprise monitoring** and analytics

### Estimated Costs
- **Development**: $45-65/month
- **Production**: $180-220/month
- **AI Usage**: Additional based on volume

## 🔗 URLs After Deployment
- Backend: `https://vigor-dev-app-xxxxxxxx-backend.azurewebsites.net`
- Frontend: `https://vigor-dev-app-xxxxxxxx-frontend.azurestaticapps.net`
- Admin: Add `/admin` to frontend URL

## 📖 Need Help?
- **Full Guide**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Enterprise Features**: [ENTERPRISE_ADMIN_SYSTEM.md](ENTERPRISE_ADMIN_SYSTEM.md)
- **Scaling**: [SCALING_ROADMAP.md](SCALING_ROADMAP.md)

## 🆘 Troubleshooting
- GitHub Actions failing? Check secrets are set correctly
- Azure login issues? Run `az login` again
- Terraform errors? Check permissions and quotas
- App not working? Check Application Insights logs
