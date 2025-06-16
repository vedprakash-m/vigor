#!/bin/bash

# Quick Fix Script: Deploy Vigor to Free Cloud Services
# This script sets up a working production deployment using free services

set -e

echo "🚀 Vigor Quick Deployment Setup"
echo "==============================="
echo ""

# Check prerequisites
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install it first."
        echo "   Install with: npm install -g $1"
        exit 1
    fi
}

echo "🔍 Checking prerequisites..."
check_command "npm"
check_command "git"

# Option 1: Deploy to Vercel (Frontend) + Railway (Backend)
echo ""
echo "🌟 Quick Deployment Options:"
echo "1. Vercel + Railway (Recommended - Free tier)"
echo "2. Netlify + Render (Alternative - Free tier)"
echo "3. Azure (Production - ~$160/month)"
echo ""

read -p "Choose option (1/2/3): " choice

case $choice in
    1)
        echo "🚀 Setting up Vercel + Railway deployment..."

        # Install CLIs
        npm install -g vercel
        npm install -g @railway/cli

        # Deploy Frontend to Vercel
        echo "📱 Deploying frontend to Vercel..."
        cd frontend
        vercel --prod
        cd ..

        # Deploy Backend to Railway
        echo "🖥️ Deploying backend to Railway..."
        cd backend
        railway login
        railway new vigor-backend
        railway add
        railway up
        cd ..

        echo "✅ Deployment complete!"
        echo "📝 Next steps:"
        echo "1. Update VITE_API_BASE_URL in frontend/.env.production"
        echo "2. Set up database URL in Railway dashboard"
        echo "3. Add environment variables to Railway"
        ;;

    2)
        echo "🚀 Setting up Netlify + Render deployment..."

        # Install Netlify CLI
        npm install -g netlify-cli

        # Deploy Frontend to Netlify
        echo "📱 Deploying frontend to Netlify..."
        cd frontend
        npm run build
        netlify deploy --prod --dir=dist
        cd ..

        echo "🖥️ Backend deployment instructions for Render:"
        echo "1. Go to https://render.com"
        echo "2. Connect your GitHub repo"
        echo "3. Create a new Web Service"
        echo "4. Set build command: pip install -r requirements.txt"
        echo "5. Set start command: python main.py"
        ;;

    3)
        echo "🚀 Setting up Azure deployment..."

        # Check Azure CLI
        if ! command -v az &> /dev/null; then
            echo "❌ Azure CLI not installed"
            echo "   Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
            exit 1
        fi

        # Deploy infrastructure
        echo "🏗️ Deploying Azure infrastructure..."
        cd infrastructure/bicep
        ./deploy.sh
        cd ../..

        # Update GitHub secrets
        echo "🔐 Required GitHub Secrets:"
        echo "- AZURE_CLIENT_ID"
        echo "- AZURE_TENANT_ID"
        echo "- AZURE_SUBSCRIPTION_ID"
        echo "- DATABASE_URL"
        echo "- OPENAI_API_KEY"
        echo "- SECRET_KEY"
        ;;

    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "🎉 Deployment setup complete!"
echo ""
echo "🔧 Next: Update CI/CD workflows to deploy to your chosen platform"
echo "📚 See docs/CI_CD_ASSESSMENT.md for detailed instructions"
