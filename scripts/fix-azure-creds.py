#!/usr/bin/env python3
"""
Script to fix Azure CLI authentication in GitHub Actions workflow.
Converts individual client-id/client-secret/tenant-id to creds parameter.
"""

import re

def fix_azure_auth():
    workflow_file = '.github/workflows/ci_cd_pipeline.yml'

    # Read the file
    with open(workflow_file, 'r') as f:
        content = f.read()

    # Pattern to match azure/login@v2 blocks with individual parameters
    pattern = r'''      - name: Azure CLI Login
        uses: azure/login@v2
        with:
          client-id: \$\{\{ secrets\.AZURE_CLIENT_ID \}\}
          client-secret: \$\{\{ secrets\.AZURE_CLIENT_SECRET \}\}
          tenant-id: \$\{\{ secrets\.AZURE_TENANT_ID \}\}
          subscription-id: \$\{\{ secrets\.AZURE_SUBSCRIPTION_ID \}\}'''

    # Replacement with creds parameter
    replacement = '''      - name: Azure CLI Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}'''

    # Apply the fix
    fixed_content = content.replace(pattern, replacement)

    # Write back to file
    with open(workflow_file, 'w') as f:
        f.write(fixed_content)

    print("✅ Fixed Azure CLI authentication to use creds parameter")
    print("Note: You need to create AZURE_CREDENTIALS secret with JSON format:")
    print('{"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}')

if __name__ == "__main__":
    fix_azure_auth()
