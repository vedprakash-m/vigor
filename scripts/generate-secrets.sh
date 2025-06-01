#!/bin/bash

# Vigor Secrets Generation Script
# Generates secure secrets for GitHub repository configuration

echo "🔐 Vigor Secrets Generator"
echo "========================="
echo ""

# Function to generate random string
generate_random() {
    openssl rand -base64 $1 | tr -d '\n'
}

echo "🎲 Generating secure secrets..."
echo ""

# PostgreSQL Admin Password
echo "📊 POSTGRES_ADMIN_PASSWORD:"
POSTGRES_PASSWORD=$(generate_random 24)
echo "   $POSTGRES_PASSWORD"
echo ""

# JWT Secret Key  
echo "🔑 SECRET_KEY:"
SECRET_KEY=$(generate_random 48)
echo "   $SECRET_KEY"
echo ""

# Admin Email (user input)
echo "📧 Enter your admin email address:"
read ADMIN_EMAIL
echo ""

echo "✅ Generated secrets for GitHub repository configuration"
echo ""
echo "📋 Copy these values to your GitHub repository secrets:"
echo "   Settings → Secrets and Variables → Actions → New repository secret"
echo ""
echo "Required Secrets:"
echo "=================="
echo ""
echo "POSTGRES_ADMIN_PASSWORD"
echo "$POSTGRES_PASSWORD"
echo ""
echo "SECRET_KEY" 
echo "$SECRET_KEY"
echo ""
echo "ADMIN_EMAIL"
echo "$ADMIN_EMAIL"
echo ""
echo "📝 Additional secrets you need to add manually:"
echo "- AZURE_CREDENTIALS (from Azure service principal)"
echo "- TFSTATE_RESOURCE_GROUP (e.g., vigor-tfstate-rg)"
echo "- TFSTATE_STORAGE_ACCOUNT (from Azure storage account)"
echo "- OPENAI_API_KEY (optional)"
echo "- GEMINI_API_KEY (recommended)"
echo "- PERPLEXITY_API_KEY (optional)"
echo ""
echo "💾 Secrets saved to secrets.txt (delete after use!)"

# Save to file for convenience (remind user to delete)
cat > secrets.txt << EOF
POSTGRES_ADMIN_PASSWORD=$POSTGRES_PASSWORD
SECRET_KEY=$SECRET_KEY
ADMIN_EMAIL=$ADMIN_EMAIL

# Add these manually:
# AZURE_CREDENTIALS=<from Azure service principal>
# TFSTATE_RESOURCE_GROUP=vigor-tfstate-rg
# TFSTATE_STORAGE_ACCOUNT=<from Azure storage account>
# OPENAI_API_KEY=<your OpenAI key>
# GEMINI_API_KEY=<your Gemini key>
# PERPLEXITY_API_KEY=<your Perplexity key>
EOF

echo ""
echo "⚠️  SECURITY WARNING: Delete secrets.txt after copying to GitHub!"
echo ""
echo "🔗 Next: Follow DEPLOYMENT_GUIDE.md for complete setup instructions" 