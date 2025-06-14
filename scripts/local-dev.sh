#!/bin/bash

set -e  # Exit on first error

# Parse command line arguments
ACTION=${1:-start}  # Default action is 'start'

case $ACTION in
  start)
    echo "🚀 Starting local development environment..."
    docker-compose up -d
    ;;

  stop)
    echo "🛑 Stopping local development environment..."
    docker-compose down
    ;;

  test-all)
    echo "🧪 Running all tests..."

    echo "Backend tests:"
    cd backend && source venv/bin/activate && python -m pytest

    echo "Frontend tests:"
    cd ../frontend && npm test

    echo "E2E tests:"
    cd .. && scripts/run_e2e_tests.sh
    ;;

  build)
    echo "🔨 Building application..."
    cd backend && source venv/bin/activate && pip install -r requirements.txt
    cd ../frontend && npm install && npm run build
    ;;

  verify)
    echo "✅ Verifying local environment..."

    # Check backend
    curl -s http://localhost:8000/api/health | grep -q "status.*up" || { echo "Backend health check failed"; exit 1; }

    # Check frontend
    curl -s http://localhost:5173 | grep -q "<title>" || { echo "Frontend health check failed"; exit 1; }

    echo "All systems operational!"
    ;;

  *)
    echo "Unknown action: $ACTION"
    echo "Usage: $0 [start|stop|test-all|build|verify]"
    exit 1
    ;;
esac
