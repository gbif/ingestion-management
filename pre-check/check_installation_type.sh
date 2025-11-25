#!/bin/bash
# Check installation type and exit if not IPT_INSTALLATION

set -e

if [ $# -ne 1 ]; then
    echo "Usage: check_installation_type.sh <issue_number>"
    exit 1
fi

ISSUE_NUMBER=$1
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Processing issue #$ISSUE_NUMBER"

# Get installation key from issue labels
INST_KEY=$(gh issue view "$ISSUE_NUMBER" --json labels | 
    jq -r '.labels[].name' | 
    grep -E '^inst: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' | 
    sed 's/^inst: //' | 
    head -1)

if [ -z "$INST_KEY" ]; then
    echo "ERROR: No installation key found in issue labels"
    exit 1
fi

echo "Found installation key: $INST_KEY"

# Get installation type using R script
INSTALLATION_TYPE=$(R_LIBS_USER="${R_LIBS_USER}" Rscript "$SCRIPT_DIR/get_installation_type.R" "$INST_KEY")

if [ $? -ne 0 ] || [ -z "$INSTALLATION_TYPE" ]; then
    echo "ERROR: Failed to retrieve installation type"
    exit 1
fi

echo "Installation type: $INSTALLATION_TYPE"

# Output the installation type for use in workflow
echo "INSTALLATION_TYPE=$INSTALLATION_TYPE" >> $GITHUB_OUTPUT || true

# Check if installation type is IPT_INSTALLATION
if [ "$INSTALLATION_TYPE" != "IPT_INSTALLATION" ]; then
    echo "Installation type is not IPT_INSTALLATION, skipping further checks"
    echo "should_continue=false" >> $GITHUB_OUTPUT || true
    exit 0
fi

echo "Installation type is IPT_INSTALLATION, continuing with pre-checks"
echo "should_continue=true" >> $GITHUB_OUTPUT || true
