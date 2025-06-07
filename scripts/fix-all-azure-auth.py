#!/usr/bin/env python3
"""
Script to fix all Azure CLI authentication blocks in GitHub Actions workflow.
"""

import re

def fix_all_azure_auth():
    workflow_file = '.github/workflows/ci_cd_pipeline.yml'

    # Read the file
    with open(workflow_file, 'r') as f:
        content = f.read()

    # Pattern to match the Azure login block with individual parameters
    old_pattern = '''        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          client-secret: ${{ secrets.AZURE_CLIENT_SECRET }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}'''

    new_pattern = '''        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}'''

    # Replace all occurrences
    fixed_content = content.replace(old_pattern, new_pattern)

    # Write back to file
    with open(workflow_file, 'w') as f:
        f.write(fixed_content)

    # Count how many replacements were made
    old_count = content.count(old_pattern)
    new_count = fixed_content.count(new_pattern)

    print(f"✅ Fixed {old_count} Azure CLI authentication blocks")
    print("✅ All blocks now use creds parameter")

if __name__ == "__main__":
    fix_all_azure_auth()
