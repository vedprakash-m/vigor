#!/bin/bash

set -e  # Exit on first error

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "❌ Error: Environment not specified"
  echo "Usage: $0 [staging|production]"
  exit 1
fi

echo "🔥 Running smoke tests for $ENVIRONMENT environment..."

if [ "$ENVIRONMENT" == "production" ]; then
  BASE_URL="https://api.vigor.production.com"
  FRONTEND_URL="https://vigor.production.com"
elif [ "$ENVIRONMENT" == "staging" ]; then
  BASE_URL="https://api.vigor.staging.com"
  FRONTEND_URL="https://vigor.staging.com"
else
  echo "❌ Error: Unknown environment: $ENVIRONMENT"
  exit 1
fi

# Create test user for smoke tests
echo "Creating test user..."
USER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/users/test" \
  -H "Content-Type: application/json" \
  -d '{"email":"smoke_test@example.com","password":"Test1234!"}')

if echo "$USER_RESPONSE" | grep -q "id"; then
  USER_ID=$(echo "$USER_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
  echo "✅ Test user created with ID: $USER_ID"
else
  echo "❌ Failed to create test user"
  echo "Response: $USER_RESPONSE"
  exit 1
fi

# Login test
echo "Testing login..."
TOKEN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"smoke_test@example.com","password":"Test1234!"}')

if echo "$TOKEN_RESPONSE" | grep -q "access_token"; then
  TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)
  echo "✅ Login successful"
else
  echo "❌ Login failed"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

# Test protected endpoint
echo "Testing protected endpoint..."
PROTECTED_RESPONSE=$(curl -s "$BASE_URL/api/v1/users/me" \
  -H "Authorization: Bearer $TOKEN")

if echo "$PROTECTED_RESPONSE" | grep -q "$USER_ID"; then
  echo "✅ Protected endpoint accessible"
else
  echo "❌ Protected endpoint failed"
  echo "Response: $PROTECTED_RESPONSE"
  exit 1
fi

# Clean up - delete test user
echo "Cleaning up test user..."
DELETE_RESPONSE=$(curl -s -X DELETE "$BASE_URL/api/v1/users/test" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN")

if echo "$DELETE_RESPONSE" | grep -q "success"; then
  echo "✅ Test user cleanup successful"
else
  echo "⚠️ Test user cleanup warning - manual cleanup may be needed"
  echo "Response: $DELETE_RESPONSE"
fi

echo "✅ All smoke tests passed for $ENVIRONMENT environment!"
