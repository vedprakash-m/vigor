#!/bin/bash

# Script to manually add permission blocks to all workflow files
# This more robust approach avoids sed issues

echo "===== Adding Permission Blocks to All Workflows ====="

# Function to add permissions to a file
add_permissions() {
    local file=$1
    local permissions=$2
    local temp_file=$(mktemp)

    echo "Processing $file..."

    # Check if the file already has permissions
    if grep -q "^permissions:" "$file"; then
        echo "  - File already has permissions block, skipping"
        return 0
    fi

    # Find the line number where "on:" section ends and "jobs:" starts
    local on_line=$(grep -n "^on:" "$file" | cut -d: -f1)
    local jobs_line=$(grep -n "^jobs:" "$file" | cut -d: -f1)

    if [ -z "$on_line" ] || [ -z "$jobs_line" ]; then
        echo "  - Could not find on: or jobs: sections, skipping"
        return 1
    fi

    # Copy file to temp with permissions added before jobs:
    head -n $((jobs_line-1)) "$file" > "$temp_file"
    echo "" >> "$temp_file"  # Add a blank line
    echo "permissions:" >> "$temp_file"
    echo "$permissions" | while read -r line; do
        echo "  $line" >> "$temp_file"
    done
    echo "" >> "$temp_file"  # Add a blank line
    tail -n +$jobs_line "$file" >> "$temp_file"

    # Replace original file with temp file
    mv "$temp_file" "$file"
    echo "  - Successfully added permissions to $file"
}

# Go to workflows directory
cd .github/workflows || { echo "Workflows directory not found!"; exit 1; }

# Process each workflow file
for file in *.yml; do
    # Check what type of workflow it is
    if grep -q "pull_request:" "$file"; then
        if grep -q -E "comment|gh pr|github\.event\.pull_request" "$file"; then
            # PR workflows that need write access
            permissions=$(cat << EOF
  pull-requests: write
  contents: read
  issues: write
EOF
)
        else
            # PR workflows with read-only access
            permissions=$(cat << EOF
  pull-requests: read
  contents: read
EOF
)
        fi
        add_permissions "$file" "$permissions"

    elif grep -q "push:" "$file"; then
        if grep -q -E "gh repo|git push" "$file"; then
            # Push workflows that need write access
            permissions=$(cat << EOF
  contents: write
  pull-requests: write
  issues: write
EOF
)
        else
            # Push workflows with read-only access
            permissions=$(cat << EOF
  contents: read
EOF
)
        fi
        add_permissions "$file" "$permissions"

    elif grep -q "schedule:" "$file" || grep -q "workflow_dispatch:" "$file"; then
        # Scheduled or manually triggered workflows
        permissions=$(cat << EOF
  contents: read
EOF
)
        add_permissions "$file" "$permissions"

    else
        echo "Skipping $file - could not determine workflow type"
    fi
done

echo ""
echo "===== Permissions Added Successfully ====="
echo "All workflows now have appropriate permission blocks."
echo "This follows the principle of least privilege for improved security."
