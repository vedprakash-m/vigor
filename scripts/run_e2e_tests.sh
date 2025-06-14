#!/bin/bash

set -e  # Exit on first error

echo "🚀 Running end-to-end tests..."

# Start backend in test mode
cd backend
source venv/bin/activate
export E2E_TEST=true
python main.py &
BACKEND_PID=$!
cd ..

# Wait for backend to be ready
sleep 5

# Run frontend in test mode
cd frontend
export VITE_API_BASE_URL=http://localhost:8000
npm run test:e2e

# Capture the exit code
E2E_STATUS=$?

# Cleanup
kill $BACKEND_PID

# Return test status
exit $E2E_STATUS
