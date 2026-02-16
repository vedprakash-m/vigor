#!/bin/bash

set -e

ENVIRONMENT=${1:-production}
BASE_URL=${BASE_URL:-"https://vigor-functions.azurewebsites.net"}

echo "🔥 Running smoke tests for $ENVIRONMENT"
echo "🔗 Target: $BASE_URL"

check_endpoint() {
  local path="$1"
  local expected="$2"
  local description="$3"

  local url="${BASE_URL}${path}"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url")

  if [ "$status" = "$expected" ]; then
    echo "✅ $description ($status)"
  else
    echo "❌ $description failed: expected $expected, got $status"
    echo "   URL: $url"
    exit 1
  fi
}

# Public health checks
check_endpoint "/api/health-simple" "200" "Health Simple"
check_endpoint "/api/health" "200" "Health"

# Auth gate smoke (without token should reject)
check_endpoint "/api/auth/me" "401" "Auth protection"

echo "✅ Smoke tests passed"
