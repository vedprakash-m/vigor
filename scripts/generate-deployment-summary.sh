#!/bin/bash
set -e

# Deployment summary generator for Vigor
echo "📊 Generating deployment summary..."

# Set defaults for variables
RG_NAME=${RG_NAME:-vigor-rg}
APP_NAME=${APP_NAME:-vigor-app-service}
DB_NAME=${DB_NAME:-vigor-db}
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S UTC")
COMMIT_SHA=${GITHUB_SHA:-unknown}
COMMIT_REF=${GITHUB_REF:-unknown}
RUNNER=${GITHUB_RUNNER_NAME:-unknown}

# Generate deployment summary
cat << EOF > deployment-summary.md
## Vigor Deployment Summary
**Timestamp:** $TIMESTAMP

### Deployment Details
- **Environment:** ${ENVIRONMENT:-production}
- **Commit:** ${COMMIT_SHA:0:8} (${COMMIT_REF})
- **Runner:** $RUNNER

### Infrastructure Status

#### App Service
$(az webapp show --resource-group $RG_NAME --name $APP_NAME --query "{name: name, state: state, url: defaultHostName}" -o json | jq -r '
"- **Name**: " + .name +
"\n- **State**: " + .state +
"\n- **URL**: https://" + .url')

#### Database
$(az postgres server show --resource-group $RG_NAME --name $DB_NAME --query "{name: name, state: userVisibleState, version: version}" -o json 2>/dev/null | jq -r '
"- **Name**: " + .name +
"\n- **State**: " + .state +
"\n- **Version**: " + .version' || echo "- Database information not available")

### Health Status
$(curl -s https://$(az webapp show --resource-group $RG_NAME --name $APP_NAME --query defaultHostName -o tsv)/health 2>/dev/null | jq '.' || echo "- Health check endpoint not accessible")

### Deployment Metrics
- **Duration:** ${DEPLOYMENT_DURATION:-"Not calculated"}
- **Cache Hit Rate:** ${CACHE_HIT_RATE:-"Not calculated"}

### Next Steps
- Monitor application logs: [App Service Logs](https://portal.azure.com/#@/resource/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.Web/sites/${APP_NAME}/logStream)
- View application insights: [App Insights](https://portal.azure.com/#@/resource/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.Insights/components/${APP_NAME})
EOF

echo "✅ Deployment summary generated at deployment-summary.md"
cat deployment-summary.md
