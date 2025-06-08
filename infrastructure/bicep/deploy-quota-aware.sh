#!/bin/bash

# Vigor Infrastructure Deployment - Quota Aware Version
# This script handles Azure quota limitations by trying different regions and tiers

set -e

echo "🚀 Vigor Infrastructure Deployment - Quota Aware"
echo "=================================================="

# Configuration
RESOURCE_GROUP="vigor-rg"
TEMPLATE_FILE="main.bicep"
PARAMETERS_FILE="parameters.bicepparam"

# Region options (in order of preference)
REGIONS=("East US 2" "West US 2" "Central US" "South Central US" "West US 3")

# SKU options (in order of preference - Basic first to avoid quota issues)
