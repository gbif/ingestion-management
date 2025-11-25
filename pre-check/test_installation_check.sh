#!/bin/bash
# Test script to check installation type without needing a GitHub issue

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Test data from the example issue
INST_KEY="08eefeeb-e20f-4482-8e0f-f218547e2f50"
DATASET_KEY="35fd702c-c615-4fb2-a7ed-5ab0e1f0946c"

echo "============================================"
echo "Testing Installation Type Check"
echo "============================================"
echo ""
echo "Dataset: $DATASET_KEY"
echo "Installation Key: $INST_KEY"
echo ""

# Get installation type using R script
echo "Fetching installation type from GBIF API..."
INSTALLATION_TYPE=$(Rscript "$SCRIPT_DIR/get_installation_type.R" "$INST_KEY")

if [ $? -ne 0 ] || [ -z "$INSTALLATION_TYPE" ]; then
    echo "❌ ERROR: Failed to retrieve installation type"
    exit 1
fi

echo "✓ Installation type: $INSTALLATION_TYPE"
echo ""

# Check if installation type is IPT_INSTALLATION
if [ "$INSTALLATION_TYPE" != "IPT_INSTALLATION" ]; then
    echo "⚠️  Installation type is NOT IPT_INSTALLATION"
    echo "   Workflow would STOP here - no further pre-checks would run"
    echo ""
    echo "Result: should_continue=false"
    exit 0
fi

echo "✓ Installation type is IPT_INSTALLATION"
echo "  Workflow would CONTINUE with further pre-checks"
echo ""
echo "Result: should_continue=true"
