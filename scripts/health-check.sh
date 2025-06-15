#!/bin/bash
set -e

# Health check script for Vigor post-deployment validation
echo "🔍 Running post-deployment health checks..."
echo "🌍 Target environment: ${1:-unknown}"
echo "🔗 Endpoint URL: $ENDPOINT_URL"

# Check environment variable
if [ -z "$ENDPOINT_URL" ]; then
  echo "❌ Missing ENDPOINT_URL environment variable"
  exit 1
fi

# Test basic connectivity first
echo "🔌 Testing basic connectivity to $ENDPOINT_URL..."
if ! curl -s --max-time 10 --connect-timeout 5 "$ENDPOINT_URL" > /dev/null 2>&1; then
  echo "❌ Cannot reach $ENDPOINT_URL - basic connectivity test failed"
  echo "   This could indicate:"
  echo "   - Service is not running"
  echo "   - DNS/network issues"
  echo "   - Firewall blocking access"
  exit 2
fi
echo "✅ Basic connectivity confirmed"

# Function to perform a health check on an endpoint
check_endpoint() {
  local url=$1
  local expected_status=$2
  local description=$3
  local max_retries=${4:-3}
  local retry_delay=${5:-5}

  echo "🔄 Checking $description at $url (expecting status $expected_status)"

  for ((i=1; i<=max_retries; i++)); do
    # More detailed curl with timeout and error info
    response=$(curl -s -w "HTTPSTATUS:%{http_code};TIME:%{time_total}" --max-time 30 --connect-timeout 10 "$url" 2>&1)
    curl_exit_code=$?

    if [ $curl_exit_code -ne 0 ]; then
      echo "⚠️ Attempt $i/$max_retries: Curl failed with exit code $curl_exit_code for $description"
      echo "   Error details: $response"
      echo "   URL attempted: $url"
    else
      # Extract status code from response
      status_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
      time_taken=$(echo "$response" | grep -o "TIME:[0-9.]*" | cut -d: -f2)

      if [ "$status_code" -eq "$expected_status" ]; then
        echo "✅ $description is healthy (status: $status_code, time: ${time_taken}s)"
        return 0
      else
        echo "⚠️ Attempt $i/$max_retries: $description returned status $status_code (expected $expected_status, time: ${time_taken}s)"
        echo "   URL: $url"
        # Show response body for debugging (first 200 chars)
        response_body=$(echo "$response" | sed 's/HTTPSTATUS:.*//; s/TIME:.*//' | head -c 200)
        if [ -n "$response_body" ]; then
          echo "   Response preview: ${response_body}..."
        fi
      fi
    fi

      if [ "$i" -lt "$max_retries" ]; then
        echo "   Retrying in $retry_delay seconds..."
        sleep $retry_delay
      fi
    fi
  done

  echo "❌ $description is unhealthy after $max_retries attempts"
  echo "   Final URL attempted: $url"
  echo "   Expected status: $expected_status"
  return 1
}

# Check API health endpoint (required)
check_endpoint "${ENDPOINT_URL}/health" 200 "API Health endpoint" 5 10

# Check additional health endpoints (optional - don't fail if they don't exist)
echo "🔍 Checking additional health endpoints..."

# Database connectivity health (optional)
if curl -s --max-time 5 "${ENDPOINT_URL}/health/database" > /dev/null 2>&1; then
  check_endpoint "${ENDPOINT_URL}/health/database" 200 "Database connectivity" 3 5
else
  echo "⚠️ Database health endpoint not available (optional)"
fi

# LLM orchestration health (optional)
if curl -s --max-time 5 "${ENDPOINT_URL}/health/llm" > /dev/null 2>&1; then
  check_endpoint "${ENDPOINT_URL}/health/llm" 200 "LLM orchestration service" 3 5
else
  echo "⚠️ LLM health endpoint not available (optional)"
fi

# Check main API endpoints are accessible
check_endpoint "${ENDPOINT_URL}/docs" 200 "API Documentation" 3 5

# Check auth endpoints are accessible (should return unauthorized for GET without token)
check_endpoint "${ENDPOINT_URL}/auth/me" 401 "Authentication service" 3 5

echo "✅ All health checks passed!"
exit 0
