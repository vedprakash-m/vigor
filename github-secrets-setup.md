# GitHub Secrets Setup for Vigor CI/CD

## 🔑 Required GitHub Secrets

Go to your repository: https://github.com/vedprakash-m/vigor/settings/secrets/actions

Click "New repository secret" for each of the following:

### 1. Azure Configuration

**AZURE_CREDENTIALS**
```json
{
  "clientId": "YOUR_CLIENT_ID_FROM_SERVICE_PRINCIPAL",
  "clientSecret": "YOUR_CLIENT_SECRET_FROM_SERVICE_PRINCIPAL", 
  "subscriptionId": "YOUR_AZURE_SUBSCRIPTION_ID",
  "tenantId": "YOUR_AZURE_TENANT_ID",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

**TFSTATE_RESOURCE_GROUP**
```
vigor-tfstate-rg
```

**TFSTATE_STORAGE_ACCOUNT**
```
vigortfstate1748797860
```

### 2. Database & Security

**POSTGRES_ADMIN_PASSWORD**
```
PnURAM3z72/HN9i1DZaXzC8S8+OmprN+
```

**SECRET_KEY**
```
ArcY9kVSHYn58ely9b+KQyEM5g8dp+TZQPPeacfMvaNER0Jp535eBDPG5QVtW6HP
```

**ADMIN_EMAIL**
```
mi.vedprakash@gmail.com
```

### 3. AI Provider Keys (Optional but Recommended)

**GEMINI_API_KEY** (Most cost-effective)
```
your-gemini-api-key-here
```

**OPENAI_API_KEY** (Optional)
```
your-openai-api-key-here
```

**PERPLEXITY_API_KEY** (Optional)
```
your-perplexity-api-key-here
```

## 🔐 IMPORTANT: Use the Values from Your Terminal

The actual values you need are displayed in your terminal output above. Copy them from there, NOT from this file.

## 🚀 Next Steps

1. **Add all secrets above** to your GitHub repository
2. **Get AI API keys** (at least Gemini for cost efficiency)
3. **Commit any final changes** to trigger deployment
4. **Monitor GitHub Actions** for deployment progress

## 📊 What Happens Next

Once secrets are configured, the CI/CD pipeline will:
- ✅ Build and test backend
- ✅ Build frontend
- ✅ Security scan with CodeQL
- ✅ Deploy Azure infrastructure with Terraform
- ✅ Deploy apps to Azure
- ✅ Run health checks
- ✅ Send deployment notifications

## 🔍 Monitoring

- **GitHub Actions**: https://github.com/vedprakash-m/vigor/actions
- **Azure Portal**: https://portal.azure.com
- **Application Insights**: Will be created during deployment

## 🆘 Troubleshooting

If deployment fails:
1. Check GitHub Actions logs
2. Verify all secrets are set correctly
3. Ensure Azure subscription has sufficient quota
4. Check Terraform state isn't locked 