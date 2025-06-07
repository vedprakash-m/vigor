#!/usr/bin/env python3
"""
Script to fix Azure CLI authentication in GitHub Actions workflow.
Adds missing client-secret parameter to all azure/login@v2 actions.
"""

import re

def fix_azure_auth():
    workflow_file = '.github/workflows/ci_cd_pipeline.yml'

    # Read the file
    with open(workflow_file, 'r') as f:
        content = f.read()

    # Pattern to match azure/login@v2 blocks that are missing client-secret
    pattern = r'(uses: azure/login@v2\s*\n\s*with:\s*\n\s*client-id: \$\{\{ secrets\.AZURE_CLIENT_ID \}\}\s*\n)(\s*tenant-id:)'

    # Replacement with client-secret added
    replacement = r'\1          client-secret: ${{ secrets.AZURE_CLIENT_SECRET }}\n\2'

    # Apply the fix with MULTILINE flag for multiple occurrences
    fixed_content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

    # Double check - fix any instances that still don't have client-secret
    lines = fixed_content.split('\n')
    result_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]
        result_lines.append(line)

        # If we find azure/login@v2, check if client-secret is missing
        if 'uses: azure/login@v2' in line:
            # Look ahead to find the with: block
            j = i + 1
            while j < len(lines) and 'with:' not in lines[j]:
                result_lines.append(lines[j])
                j += 1

            if j < len(lines):  # Found 'with:'
                result_lines.append(lines[j])  # Add 'with:' line
                j += 1

                # Check if client-secret exists in the next few lines
                has_client_secret = False
                client_id_line_idx = -1

                # Look for client-id and check for client-secret
                k = j
                while k < len(lines) and lines[k].strip() and not lines[k].startswith('  - name:'):
                    if 'client-id:' in lines[k]:
                        client_id_line_idx = k
                    if 'client-secret:' in lines[k]:
                        has_client_secret = True
                    k += 1

                # If no client-secret found, add it after client-id
                if not has_client_secret and client_id_line_idx >= 0:
                    # Add all lines up to client-id
                    while j <= client_id_line_idx:
                        result_lines.append(lines[j])
                        j += 1

                    # Add client-secret line with same indentation as client-id
                    indent = len(lines[client_id_line_idx]) - len(lines[client_id_line_idx].lstrip())
                    client_secret_line = ' ' * indent + 'client-secret: ${{ secrets.AZURE_CLIENT_SECRET }}'
                    result_lines.append(client_secret_line)

                    # Continue with rest of the lines
                    i = j - 1  # -1 because we'll increment at the end
                else:
                    # Add remaining lines in the with block
                    while j < k:
                        result_lines.append(lines[j])
                        j += 1
                    i = j - 1
            else:
                i = j - 1

        i += 1

    # Write back to file
    with open(workflow_file, 'w') as f:
        f.write('\n'.join(result_lines))

    print("✅ Fixed Azure CLI authentication in GitHub Actions workflow")

if __name__ == "__main__":
    fix_azure_auth()
