# Vigor Platform - Operational Runbooks

This directory contains operational runbooks for managing the Vigor platform infrastructure on Azure.

## 📚 Table of Contents

1. [Deployment Procedures](#deployment-procedures)
2. [Monitoring and Alerting](#monitoring-and-alerting)
3. [Backup and Recovery](#backup-and-recovery)
4. [Performance Management](#performance-management)
5. [Security Operations](#security-operations)
6. [Troubleshooting Guide](#troubleshooting-guide)
7. [Emergency Procedures](#emergency-procedures)

## 🚀 Deployment Procedures

### Initial Environment Setup

1. **Prerequisites**

   ```bash
   # Install Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

   # Login to Azure
   az login

   # Set subscription
   az account set --subscription "your-subscription-id"
   ```

2. **Deploy Infrastructure**

   ```bash
   # Deploy to development
   ./infrastructure/azure/deploy.sh \
     --environment dev \
     --resource-group vigor-dev-rg \
     --location "East US" \
     --admin-login vigoradmin \
     --admin-password "SecurePassword123!"

   # Deploy to staging
   ./infrastructure/azure/deploy.sh \
     --environment staging \
     --resource-group vigor-staging-rg \
     --location "East US" \
     --admin-login vigoradmin \
     --admin-password "SecurePassword123!"

   # Deploy to production
   ./infrastructure/azure/deploy.sh \
     --environment prod \
     --resource-group vigor-prod-rg \
     --location "East US" \
     --admin-login vigoradmin \
     --admin-password "SecurePassword123!"
   ```

3. **Configure Secrets**
   ```bash
   # Set up secrets for each environment
   ./infrastructure/azure/secrets-management.sh \
     --environment dev \
     --resource-group vigor-dev-rg \
     --key-vault vigor-dev-kv
   ```

### Application Deployment

1. **Build and Push Container**

   ```bash
   # Build the application container
   docker build -t vigor-app:latest .

   # Tag for Azure Container Registry
   docker tag vigor-app:latest vigorprodacr.azurecr.io/vigor-app:latest

   # Push to registry
   docker push vigorprodacr.azurecr.io/vigor-app:latest
   ```

2. **Deploy Application**

   ```bash
   # Deploy to App Service
   az webapp config container set \
     --name vigor-prod-app \
     --resource-group vigor-prod-rg \
     --docker-custom-image-name vigorprodacr.azurecr.io/vigor-app:latest

   # Restart the application
   az webapp restart \
     --name vigor-prod-app \
     --resource-group vigor-prod-rg
   ```

## 📊 Monitoring and Alerting

### Health Check Endpoints

- **Basic Health**: `GET /health`
- **Readiness**: `GET /health/ready`
- **Liveness**: `GET /health/live`
- **Detailed**: `GET /health/detailed`
- **Metrics**: `GET /health/metrics`

### Key Metrics to Monitor

1. **Application Metrics**

   - Response time (target: <2s average)
   - Error rate (target: <1%)
   - Request throughput
   - Active users

2. **Infrastructure Metrics**

   - CPU usage (alert: >80%)
   - Memory usage (alert: >85%)
   - Disk usage (alert: >90%)
   - Network latency

3. **Database Metrics**
   - Connection count
   - Query performance
   - Lock waits
   - Buffer hit ratio

### Alert Configuration

Alerts are automatically configured via the monitoring template:

```bash
# Deploy monitoring infrastructure
az deployment group create \
  --resource-group vigor-prod-rg \
  --template-file infrastructure/azure/monitoring-template.json \
  --parameters environment=prod \
    appServiceName=vigor-prod-app \
    databaseServerName=vigor-prod-postgres \
    alertEmailAddress=admin@vigor.app
```

## 💾 Backup and Recovery

### Automated Backups

Daily backups are configured for:

- Database (PostgreSQL dumps)
- Application data (file storage)
- Configuration (Key Vault, App Service settings)

### Manual Backup

```bash
# Full backup
./infrastructure/azure/backup-restore.sh \
  --environment prod \
  --resource-group vigor-prod-rg \
  --type full

# Incremental backup
./infrastructure/azure/backup-restore.sh \
  --environment prod \
  --type incremental
```

### Disaster Recovery

1. **Point-in-Time Database Restore**

   ```bash
   # Restore database to specific point in time
   az postgres server restore \
     --source-server vigor-prod-postgres \
     --name vigor-prod-postgres-restored \
     --resource-group vigor-prod-rg \
     --restore-point-in-time "2024-01-15T10:00:00Z"
   ```

2. **Full Environment Recovery**
   ```bash
   # Restore from backup
   ./infrastructure/azure/backup-restore.sh \
     --restore \
     --restore-date 2024-01-15 \
     --environment prod
   ```

## ⚡ Performance Management

### Performance Analysis

```bash
# Analyze current performance
./infrastructure/azure/performance-optimization.sh \
  --environment prod \
  --operation analyze
```

### Scaling Operations

```bash
# Scale up during high load
./infrastructure/azure/performance-optimization.sh \
  --environment prod \
  --operation scale-up

# Scale down during low usage
./infrastructure/azure/performance-optimization.sh \
  --environment prod \
  --operation scale-down
```

### Performance Optimization

```bash
# Apply performance optimizations
./infrastructure/azure/performance-optimization.sh \
  --environment prod \
  --operation optimize
```

## 🔒 Security Operations

### Key Vault Management

1. **Rotate Secrets**

   ```bash
   # Generate new secrets
   ./infrastructure/azure/secrets-management.sh \
     --environment prod \
     --key-vault vigor-prod-kv \
     --force
   ```

2. **Access Review**
   ```bash
   # List Key Vault access policies
   az keyvault show \
     --name vigor-prod-kv \
     --query "properties.accessPolicies"
   ```

### Security Monitoring

- Monitor failed login attempts
- Track unusual access patterns
- Review API key usage
- Audit database access

## 🔧 Troubleshooting Guide

### Common Issues

1. **Application Won't Start**

   ```bash
   # Check application logs
   az webapp log tail \
     --name vigor-prod-app \
     --resource-group vigor-prod-rg

   # Check container logs
   az webapp log config \
     --name vigor-prod-app \
     --resource-group vigor-prod-rg \
     --docker-container-logging filesystem
   ```

2. **Database Connection Issues**

   ```bash
   # Test database connectivity
   psql "host=vigor-prod-postgres.postgres.database.azure.com port=5432 dbname=vigor user=vigoradmin@vigor-prod-postgres sslmode=require"

   # Check database metrics
   az monitor metrics list \
     --resource vigor-prod-postgres \
     --metric "active_connections"
   ```

3. **High CPU Usage**

   ```bash
   # Check current CPU usage
   az monitor metrics list \
     --resource vigor-prod-app \
     --metric "CpuPercentage"

   # Scale up if needed
   ./infrastructure/azure/performance-optimization.sh \
     --environment prod \
     --operation scale-up
   ```

4. **SSL Certificate Issues**

   ```bash
   # Check certificate status
   az webapp config ssl list \
     --resource-group vigor-prod-rg

   # Renew certificate
   az webapp config ssl bind \
     --certificate-thumbprint <thumbprint> \
     --ssl-type SNI \
     --name vigor-prod-app \
     --resource-group vigor-prod-rg
   ```

### Log Analysis

```bash
# Application logs
az webapp log download \
  --name vigor-prod-app \
  --resource-group vigor-prod-rg

# Database logs
az postgres server-logs list \
  --server-name vigor-prod-postgres \
  --resource-group vigor-prod-rg
```

## 🚨 Emergency Procedures

### Incident Response

1. **Service Outage**

   - Check health endpoints
   - Review recent deployments
   - Check resource metrics
   - Scale up if resource exhaustion
   - Roll back if deployment issue

2. **Security Incident**

   - Rotate all API keys and secrets
   - Review access logs
   - Block suspicious IPs
   - Notify stakeholders

3. **Data Loss**
   - Stop all writes to affected system
   - Assess scope of data loss
   - Restore from most recent backup
   - Validate data integrity

### Emergency Contacts

- **Operations Team**: ops@vigor.app
- **Security Team**: security@vigor.app
- **Development Team**: dev@vigor.app

### Escalation Matrix

1. **Level 1**: Operations team handles routine issues
2. **Level 2**: Senior engineers for complex technical issues
3. **Level 3**: Architecture team for system-wide problems
4. **Level 4**: Management for business-critical outages

## 📋 Maintenance Procedures

### Monthly Tasks

- Review and update secrets
- Analyze performance metrics
- Review backup integrity
- Update security patches
- Cost optimization review

### Quarterly Tasks

- Disaster recovery testing
- Security audit
- Performance baseline review
- Capacity planning
- Documentation updates

### Annual Tasks

- Complete security assessment
- Infrastructure architecture review
- Business continuity plan update
- Compliance audit
- Technology stack evaluation

## 📞 Support Information

### Documentation

- [Azure Documentation](https://docs.microsoft.com/azure/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Documentation](https://docs.docker.com/)

### Monitoring Dashboards

- Azure Portal: https://portal.azure.com
- Application Insights: https://portal.azure.com/#@{tenant}/resource/subscriptions/{subscription}/resourceGroups/vigor-prod-rg/providers/Microsoft.Insights/components/vigor-prod-insights
- Log Analytics: https://portal.azure.com/#@{tenant}/resource/subscriptions/{subscription}/resourceGroups/vigor-prod-rg/providers/Microsoft.OperationalInsights/workspaces/vigor-prod-logs

---

**Last Updated**: January 2024
**Version**: 1.0
**Owner**: Vigor Operations Team
