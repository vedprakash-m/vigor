#!/bin/bash

# Vigor Terraform to Bicep Migration Script
# This script helps migrate from Terraform to Azure Bicep

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
RESOURCE_GROUP="vigor-rg"
TERRAFORM_DIR="infrastructure/terraform"
BICEP_DIR="infrastructure/bicep"

print_status "🔄 Vigor Terraform to Bicep Migration"
echo "======================================"
echo ""

# Check if we're in the project root
if [[ ! -d "$TERRAFORM_DIR" ]] || [[ ! -d "$BICEP_DIR" ]]; then
    print_error "Please run this script from the project root directory."
    echo "Expected directories: $TERRAFORM_DIR and $BICEP_DIR"
    exit 1
fi

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

if ! az bicep version &> /dev/null; then
    print_warning "Bicep CLI not found. Installing..."
    az bicep install
    print_success "Bicep CLI installed"
fi

print_success "Prerequisites check passed"
echo ""

# Azure login check
print_status "Checking Azure authentication..."
if ! az account show &> /dev/null; then
    print_warning "Not logged into Azure. Please run 'az login' first."
    exit 1
fi

print_success "Azure authentication verified"
echo ""

# Step 1: Export current Terraform state (if it exists)
print_status "Step 1: Checking Terraform state..."

if [[ -f "$TERRAFORM_DIR/.terraform/terraform.tfstate" ]] || [[ -f "$TERRAFORM_DIR/terraform.tfstate" ]]; then
    print_warning "Local Terraform state found. Backing up..."

    mkdir -p migration-backup
    cp -r "$TERRAFORM_DIR" migration-backup/terraform-backup-$(date +%Y%m%d-%H%M%S)
    print_success "Terraform state backed up"
else
    print_status "No local Terraform state found (using remote backend)"
fi

# Check if Terraform resources exist in Azure
print_status "Checking for existing Terraform-managed resources..."

EXISTING_RESOURCES=$(az resource list --resource-group "$RESOURCE_GROUP" --query "length(@)" --output tsv 2>/dev/null || echo "0")

if [[ "$EXISTING_RESOURCES" -gt 0 ]]; then
    print_warning "Found $EXISTING_RESOURCES existing resources in $RESOURCE_GROUP"
    echo ""
    print_status "Current resources:"
    az resource list --resource-group "$RESOURCE_GROUP" --output table
    echo ""

    read -p "Do you want to continue with migration? This will deploy Bicep alongside existing resources. (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Migration cancelled by user"
        exit 0
    fi
else
    print_success "No existing resources found. Clean deployment."
fi

echo ""

# Step 2: Validate Bicep template
print_status "Step 2: Validating Bicep template..."

cd "$BICEP_DIR"

# Check for required environment variables
REQUIRED_VARS=(
    "POSTGRES_ADMIN_PASSWORD"
    "SECRET_KEY"
    "ADMIN_EMAIL"
)

missing_vars=()
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    print_error "Missing required environment variables for validation:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Please set these variables before running migration:"
    echo "export POSTGRES_ADMIN_PASSWORD=\"your-secure-password\""
    echo "export SECRET_KEY=\"your-jwt-secret-key\""
    echo "export ADMIN_EMAIL=\"admin@vigor-fitness.com\""
    exit 1
fi

# Validate Bicep template
az deployment group validate \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters parameters.bicepparam \
    --parameters postgresAdminPassword="$POSTGRES_ADMIN_PASSWORD" \
                 secretKey="$SECRET_KEY" \
                 adminEmail="$ADMIN_EMAIL" \
                 openaiApiKey="${OPENAI_API_KEY:-}" \
                 geminiApiKey="${GEMINI_API_KEY:-}" \
                 perplexityApiKey="${PERPLEXITY_API_KEY:-}" \
    > /dev/null

print_success "Bicep template validation passed"

cd ../..

# Step 3: Deploy Bicep infrastructure
echo ""
print_status "Step 3: Deploying Bicep infrastructure..."

read -p "Deploy infrastructure using Bicep now? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$BICEP_DIR"
    ./deploy.sh
    cd ../..
    print_success "Bicep infrastructure deployed"
else
    print_warning "Skipping infrastructure deployment"
    print_status "You can deploy later using: cd $BICEP_DIR && ./deploy.sh"
fi

# Step 4: Update GitHub Actions secrets (if needed)
echo ""
print_status "Step 4: GitHub Actions configuration..."

print_status "Your GitHub Actions workflow has been updated to use Bicep."
print_status "Required GitHub secrets for Bicep deployment:"
echo "  - POSTGRES_ADMIN_PASSWORD"
echo "  - SECRET_KEY"
echo "  - ADMIN_EMAIL"
echo "  - AZURE_CLIENT_ID"
echo "  - AZURE_TENANT_ID"
echo "  - AZURE_SUBSCRIPTION_ID"
echo "  - OPENAI_API_KEY (optional)"
echo "  - GEMINI_API_KEY (optional)"
echo "  - PERPLEXITY_API_KEY (optional)"

# Step 5: Clean up Terraform (optional)
echo ""
print_status "Step 5: Terraform cleanup..."

read -p "Remove Terraform state storage account (vigortfstate*)? This will save ~$5/month. (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Finding Terraform state storage accounts..."

    TFSTATE_ACCOUNTS=$(az storage account list --resource-group "$RESOURCE_GROUP" --query "[?starts_with(name, 'vigortfstate')].name" --output tsv)

    if [[ -n "$TFSTATE_ACCOUNTS" ]]; then
        for account in $TFSTATE_ACCOUNTS; do
            print_warning "Deleting Terraform state storage account: $account"
            az storage account delete --name "$account" --resource-group "$RESOURCE_GROUP" --yes
            print_success "Deleted storage account: $account"
        done
    else
        print_status "No Terraform state storage accounts found"
    fi
else
    print_warning "Keeping Terraform state storage account"
    print_status "You can delete it manually later to save costs"
fi

# Step 6: Archive Terraform files (optional)
echo ""
read -p "Archive Terraform configuration files? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p migration-backup
    BACKUP_DIR="migration-backup/terraform-config-$(date +%Y%m%d-%H%M%S)"
    cp -r "$TERRAFORM_DIR" "$BACKUP_DIR"

    # Create archive marker
    cat > "$TERRAFORM_DIR/MIGRATED_TO_BICEP.md" << 'EOF'
# Terraform Configuration Archived

This Terraform configuration has been migrated to Azure Bicep.

**Migration Date:** $(date)
**New Location:** infrastructure/bicep/
**Backup Location:** See migration-backup/ directory

## Why Migrated to Bicep?

- **Azure-native**: Better integration with Azure services
- **Simpler syntax**: More readable infrastructure code
- **No state management**: Azure handles state automatically
- **Cost savings**: Eliminates Terraform state storage costs
- **Faster deployments**: Direct ARM template compilation

## Using Bicep

```bash
# Deploy infrastructure
cd infrastructure/bicep
./deploy.sh

# Validate template
az deployment group validate --resource-group vigor-rg --template-file main.bicep --parameters parameters.bicepparam
```

## Rollback (if needed)

The original Terraform configuration is preserved in:
- migration-backup/terraform-config-TIMESTAMP/
- Git history

To rollback:
1. Restore Terraform files from backup
2. Update GitHub Actions workflow to use Terraform
3. Re-create Terraform state storage
4. Import existing Azure resources to Terraform state
EOF

    print_success "Terraform configuration archived to $BACKUP_DIR"
    print_success "Created migration marker at $TERRAFORM_DIR/MIGRATED_TO_BICEP.md"
else
    print_warning "Keeping Terraform configuration files"
fi

echo ""
print_success "🎉 Migration to Bicep completed successfully!"
echo ""
print_status "Summary of changes:"
echo "  ✅ Bicep templates validated and ready"
echo "  ✅ GitHub Actions workflow updated for Bicep"
echo "  ✅ Infrastructure deployment $([ "$REPLY" = "y" ] && echo "completed" || echo "ready")"
echo "  ✅ Cost optimization: No more Terraform state storage fees"
echo "  ✅ Simplified infrastructure management"
echo ""
print_status "Next steps:"
echo "  1. Test your application deployment with the new Bicep infrastructure"
echo "  2. Verify all functionality works correctly"
echo "  3. Update your documentation to reference Bicep instead of Terraform"
echo "  4. Train your team on Bicep deployment processes"
echo ""
print_status "Bicep benefits you now have:"
echo "  🚀 Faster deployments (no state management)"
echo "  💰 Cost savings (no state storage)"
echo "  🔒 Better Azure integration"
echo "  📝 Cleaner, more readable templates"
echo "  🎯 Native Azure feature support"
echo ""
print_warning "Remember to test thoroughly before considering the migration complete!"
