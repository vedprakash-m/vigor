#!/bin/bash

# Vigor GitHub Repository Setup Script
# This script helps setup the GitHub repository and initial configuration

set -e

echo "🚀 Vigor GitHub Repository Setup"
echo "================================="

# Check if required tools are installed
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install it first."
        exit 1
    fi
}

echo "📋 Checking prerequisites..."
check_tool git
check_tool gh
check_tool az

# Get GitHub username
echo "👤 Please enter your GitHub username:"
read GITHUB_USERNAME

# Confirm repository creation
echo "📁 This will create a repository: https://github.com/$GITHUB_USERNAME/vigor"
echo "Continue? (y/n)"
read -r CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "❌ Setup cancelled."
    exit 1
fi

# Create GitHub repository
echo "🏗️ Creating GitHub repository..."
gh repo create vigor --public --description "AI-powered fitness app with admin controls and Azure infrastructure"

# Clone repository
echo "📥 Cloning repository..."
git clone https://github.com/$GITHUB_USERNAME/vigor.git vigor-repo
cd vigor-repo

# Copy files from current directory (assuming script is run from vigor project root)
echo "📄 Copying project files..."
cp -r ../* . 2>/dev/null || true
cp -r ../.[!.]* . 2>/dev/null || true

# Remove the copied repository folder to avoid recursion
rm -rf vigor-repo 2>/dev/null || true

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
backend/venv/
backend/__pycache__/
backend/*.pyc
backend/.pytest_cache/

# Environment files
.env
.env.local
.env.production
backend/.env

# Database
*.db
*.sqlite
*.sqlite3

# Logs
*.log
logs/

# Build outputs
frontend/dist/
backend/build/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
terraform.tfvars

# Azure
.azure/

# Coverage reports
coverage/
.coverage
htmlcov/

# Temporary files
*.tmp
*.temp
EOF
fi

# Initial commit
echo "📤 Creating initial commit..."
git add .
git commit -m "Initial commit: Vigor fitness app with Azure IaC and CI/CD

Features:
- FastAPI backend with AI provider management
- React frontend with admin dashboard
- Azure infrastructure as code (Terraform)
- GitHub Actions CI/CD pipeline
- Enterprise admin controls for AI cost optimization
- Support for OpenAI GPT-4o, Gemini, and Perplexity providers"

git branch -M main
git push -u origin main

echo ""
echo "✅ GitHub repository created successfully!"
echo ""
echo "🔗 Repository URL: https://github.com/$GITHUB_USERNAME/vigor"
echo ""
echo "📋 Next Steps:"
echo "1. Set up Azure prerequisites (see DEPLOYMENT_GUIDE.md)"
echo "2. Configure GitHub secrets"
echo "3. Trigger the first deployment"
echo ""
echo "📖 Full instructions: https://github.com/$GITHUB_USERNAME/vigor/blob/main/DEPLOYMENT_GUIDE.md"
echo ""
echo "🎉 Happy deploying!"
