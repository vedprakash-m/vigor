#!/bin/bash
# Simple E2E test script for local validation

set -e

echo "🧪 Running Local E2E Tests"
echo "=========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Cleanup function
cleanup() {
    print_step "Cleaning up servers"
    if [[ -n "$BACKEND_PID" ]]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [[ -n "$FRONTEND_PID" ]]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    sleep 2
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Build frontend
print_step "Building frontend"
cd frontend
npm run build || {
    print_error "Frontend build failed"
    exit 1
}

# Start backend server
print_step "Starting backend server"
cd ../backend

# Check if venv exists and activate it
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
else
    print_error "Backend virtual environment not found"
    exit 1
fi

# Set environment variables
export DATABASE_URL="sqlite:///test.db"
export LLM_PROVIDER="fallback"
export OPENAI_API_KEY="sk-placeholder"

# Start backend in background
python main.py &
BACKEND_PID=$!
print_success "Backend server started (PID: $BACKEND_PID)"

# Wait for backend
sleep 8

# Start frontend dev server
print_step "Starting frontend dev server"
cd ../frontend
npm run dev &
FRONTEND_PID=$!
print_success "Frontend dev server started (PID: $FRONTEND_PID)"

# Wait for frontend
print_step "Waiting for frontend to be ready"
sleep 10

# Check if servers are responding
print_step "Checking server health"
if curl -s http://localhost:8000/health > /dev/null; then
    print_success "Backend health check passed"
else
    print_error "Backend health check failed"
fi

if curl -s http://localhost:5173 > /dev/null; then
    print_success "Frontend server responding"
else
    print_error "Frontend server not responding"
fi

# Run E2E tests
print_step "Running E2E tests"
npm run test:e2e || {
    print_error "E2E tests failed"
    exit 1
}

print_success "E2E tests completed successfully!"
