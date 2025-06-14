#!/bin/bash

# Script to fix common issues in GitHub Actions workflows
# This script adds permission blocks and fixes other common issues

echo "===== Adding Permission Blocks to Workflows ====="

# Navigate to workflows directory
cd .github/workflows || { echo "Workflows directory not found!"; exit 1; }

# Add permissions block to all workflow files
for file in *.yml; do
    echo "Processing $file..."

    # Check if permissions block already exists
    if ! grep -q "permissions:" "$file"; then
        # Check if it's a PR-related workflow that needs write permissions
        if grep -q "pull_request" "$file"; then
            # For PR workflows that need to comment or modify PRs
            if grep -q "comment" "$file" || grep -q "gh pr" "$file" || grep -q "github.event.pull_request" "$file"; then
                # Insert permissions block after the "on:" section
                sed -i.bak '/^on:/,/^jobs:/{/^jobs:/i\
permissions:\
  pull-requests: write\
  contents: read\
  issues: write\
}' "$file"
                echo "  - Added PR write permissions to $file"
            else
                # Basic read permissions for PR workflows that don't modify
                sed -i.bak '/^on:/,/^jobs:/{/^jobs:/i\
permissions:\
  pull-requests: read\
  contents: read\
}' "$file"
                echo "  - Added basic read permissions to $file"
            fi
        else
            # For push or schedule based workflows
            if grep -q "push:" "$file" || grep -q "schedule:" "$file"; then
                if grep -q "gh repo" "$file" || grep -q "git push" "$file"; then
                    # For workflows that need to push changes
                    sed -i.bak '/^on:/,/^jobs:/{/^jobs:/i\
permissions:\
  contents: write\
  pull-requests: write\
  issues: write\
}' "$file"
                    echo "  - Added write permissions to $file"
                else
                    # Default least privilege for other workflows
                    sed -i.bak '/^on:/,/^jobs:/{/^jobs:/i\
permissions:\
  contents: read\
}' "$file"
                    echo "  - Added read-only permissions to $file"
                fi
            fi
        fi
    else
        echo "  - Permissions block already exists in $file"
    fi

    # Remove backup files
    rm -f "$file.bak"
done

echo ""
echo "===== Adding YAML Document Start Markers ====="

# Add YAML document start markers to the beginning of files
for file in *.yml; do
    echo "Adding document start marker to $file..."

    # Check if file already has a document start marker
    if ! grep -q "^---" "$file"; then
        sed -i.bak '1s/^/---\n/' "$file"
        echo "  - Added document start marker to $file"
    else
        echo "  - Document start marker already exists in $file"
    fi

    # Remove backup files
    rm -f "$file.bak"
done

echo ""
echo "===== Fixed Common Workflow Issues ====="
echo "All workflows now have permission blocks and document start markers added."
echo "This improves security and YAML compliance."
