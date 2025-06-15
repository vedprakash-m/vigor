#!/bin/bash
set -e

# Health check script for Vigor post-deployment validation
echo "🔍 Running post-deployment health checks..."

# Check environment variable
if [ -z "$ENDPOINT_URL" ]; then
  echo "❌ Missing ENDPOINT_URL environment variable"
  exit 1
fi

# Function to perform a health check on an endpoint
check_endpoint() {
  local url=$1
  local expected_status=$2
  local description=$3
  local max_retries=${4:-3}
  local retry_delay=${5:-5}

  echo "🔄 Checking $description at $url (expecting status $expected_status)"

  for ((i=1; i<=max_retries; i++)); do
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    if [ "$status_code" -eq "$expected_status" ]; then
      echo "✅ $description is healthy (status: $status_code)"
      return 0
    else
      echo "⚠️ Attempt $i/$max_retries: $description returned status $status_code (expected $expected_status)"

      if [ "$i" -lt "$max_retries" ]; then
        echo "Retrying in $retry_delay seconds..."
        sleep $retry_delay
      fi
    fi
  done

  echo "❌ $description is unhealthy after $max_retries attempts"
  return 1
}

# Check API health endpoint
check_endpoint "${ENDPOINT_URL}/health" 200 "API Health endpoint" 5 10

# Check database connectivity health
check_endpoint "${ENDPOINT_URL}/health/database" 200 "Database connectivity" 3 5

# Check LLM orchestration health
check_endpoint "${ENDPOINT_URL}/health/llm" 200 "LLM orchestration service" 3 5

# Check main API endpoints are accessible
check_endpoint "${ENDPOINT_URL}/docs" 200 "API Documentation" 3 5

# Check auth endpoints are accessible (should return unauthorized for GET without token)
check_endpoint "${ENDPOINT_URL}/auth/me" 401 "Authentication service" 3 5

echo "✅ All health checks passed!"
exit 0
