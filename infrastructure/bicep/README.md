# Deploy Vigor Infrastructure with Azure Bicep

This directory contains the Azure Bicep templates for deploying the Vigor fitness application infrastructure.

## Files Overview

- `main.bicep` - Main infrastructure template defining all Azure resources
- `parameters.bicepparam` - Production environment parameters
- `deploy.sh` - Deployment script for local/manual deployment
- `README.md` - This file

## Features

### Infrastructure Components

- **Resource Groups**:
  - `vigor-rg` runtime stack (App Service, Static Web App, Key Vault, ACR, etc.)
  - `vigor-db-rg` persistent layer (PostgreSQL + Storage Account)
- **App Service Plan**: Standard S1 tier for production workloads
- **App Service**: Linux-based backend hosting with Python 3.11
- **Static Web App**: Frontend hosting with global CDN
- **PostgreSQL**: Flexible server with 10GB storage
- **Redis Cache**: Standard 1GB cache for session management
- **Storage Account**: Blob storage for application data
- **Key Vault**: Secure secret management for API keys
- **Container Registry**: Docker image hosting
- **Application Insights**: Performance monitoring and analytics
- **Log Analytics**: Centralized logging workspace

### Security Features

- Private network access for Key Vault and Storage
- System-assigned managed identities
- TLS 1.2 minimum encryption
- Azure Key Vault integration for secrets
- HTTPS-only enforcement

### Cost Optimization

- Zone-redundant storage only in production
- Conditional high availability features
- Optimized SKUs for development vs production
- Built-in budget monitoring

## Deployment

### Prerequisites

1. **Azure CLI** installed and authenticated
2. **Bicep CLI** installed (`az bicep install`)
3. **Required secrets** available as environment variables

### Quick Deployment

```bash
# Set required environment variables
export POSTGRES_ADMIN_PASSWORD="your-secure-password"
export SECRET_KEY="your-jwt-secret-key"
export GEMINI_API_KEY="your-gemini-api-key"
export ADMIN_EMAIL="admin@vigor-fitness.com"

# Deploy infrastructure
./deploy.sh
```

### Manual Deployment

```bash
# Create resource group
az group create --name vigor-rg --location "East US"

# Deploy with parameters
az deployment group create \
  --resource-group vigor-rg \
  --template-file main.bicep \
  --parameters parameters.bicepparam \
  --parameters postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD" \
               secretKey="$SECRET_KEY" \
               geminiApiKey="$GEMINI_API_KEY" \
               adminEmail="$ADMIN_EMAIL"
```

### Validate Template

```bash
# Validate Bicep template
az deployment group validate \
  --resource-group vigor-rg \
  --template-file main.bicep \
  --parameters parameters.bicepparam
```

## CI/CD Integration

The Bicep templates integrate with GitHub Actions for automated deployment:

```yaml
- name: Deploy Infrastructure
  run: |
    az deployment group create \
      --resource-group vigor-rg \
      --template-file infrastructure/bicep/main.bicep \
      --parameters infrastructure/bicep/parameters.bicepparam \
      --parameters postgresAdminPassword="${{ secrets.POSTGRES_ADMIN_PASSWORD }}" \
                   secretKey="${{ secrets.SECRET_KEY }}" \
                   geminiApiKey="${{ secrets.GEMINI_API_KEY }}" \
                   openaiApiKey="${{ secrets.OPENAI_API_KEY }}" \
                   perplexityApiKey="${{ secrets.PERPLEXITY_API_KEY }}" \
                   adminEmail="${{ secrets.ADMIN_EMAIL }}"
```

## Monitoring and Management

### Check Deployment Status

```bash
# List all deployments
az deployment group list --resource-group vigor-rg --output table

# Get deployment details
az deployment group show --resource-group vigor-rg --name main
```

### View Resources

```bash
# List all resources in the group
az resource list --resource-group vigor-rg --output table
```

### Access Application URLs

```bash
# Get backend URL
az webapp show --resource-group vigor-rg --name vigor-prod-app-* --query defaultHostName

# Get frontend URL
az staticwebapp show --resource-group vigor-rg --name vigor-prod-app-*-frontend --query defaultHostname
```

## Cost Management

### Estimated Monthly Costs (USD)

- **Total**: $150-180/month
- **App Service Plan (S1)**: $73/month
- **PostgreSQL (10GB)**: $45-65/month
- **Redis (1GB Standard)**: $25/month
- **Static Web App**: $10/month
- **Storage & Other**: $5-15/month

### Cost Optimization Tips

1. Use **Basic** tiers for development/testing
2. Enable **auto-scaling** during low usage periods
3. Monitor costs with **Azure Cost Management**
4. Use **reserved instances** for predictable workloads

## Troubleshooting

### Common Issues

1. **Deployment Fails**: Check resource name uniqueness and quotas
2. **Permission Denied**: Ensure proper Azure RBAC permissions
3. **Secret Access**: Verify Key Vault access policies and managed identity

### Debug Commands

```bash
# Check deployment errors
az deployment group list --resource-group vigor-rg --query "[?provisioningState=='Failed']"

# View detailed error messages
az deployment operation group list --resource-group vigor-rg --name main
```

## Migration from Terraform

If migrating from Terraform:

1. **Export existing state**: Document current resource configurations
2. **Deploy Bicep**: Create resources with matching configurations
3. **Update CI/CD**: Replace Terraform steps with Bicep deployment
4. **Clean up**: Remove Terraform state storage and configuration
5. **Verify**: Test full application deployment and functionality

## Next Steps

1. Deploy infrastructure using the deployment script
2. Configure GitHub Actions with Bicep deployment
3. Test application deployment and functionality
4. Set up monitoring and alerting
5. Configure custom domain and SSL certificates (optional)
