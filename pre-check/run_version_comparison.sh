#!/bin/bash
# Run IPT version comparison check for pre-check workflow

set -e

if [ $# -ne 1 ]; then
    echo "Usage: run_version_comparison.sh <issue_number>"
    exit 1
fi

ISSUE_NUMBER=$1
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Processing issue #$ISSUE_NUMBER for version comparison"

# Get dataset key from issue labels
DATASET_KEY=$(gh issue view "$ISSUE_NUMBER" --json labels | 
    jq -r '.labels[].name' | 
    grep -E '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' | 
    grep -vE '^(pub|inst): ' | 
    head -1)

if [ -z "$DATASET_KEY" ]; then
    echo "ERROR: No dataset key found in issue labels"
    exit 1
fi

echo "Found dataset key: $DATASET_KEY"
echo ""

# Run the R script - don't capture output, let it stream
Rscript "$SCRIPT_DIR/compare_versions_precheck.R" "$DATASET_KEY"
EXIT_CODE=$?

# Exit with the R script's exit code
exit $EXIT_CODE
