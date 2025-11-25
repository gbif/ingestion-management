#!/bin/bash
# Test the version comparison script locally without needing a GitHub issue

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Example dataset from your issue
DATASET_KEY="35fd702c-c615-4fb2-a7ed-5ab0e1f0946c"

if [ $# -eq 1 ]; then
    DATASET_KEY=$1
fi

echo "============================================"
echo "Testing Version Comparison"
echo "============================================"
echo "Dataset Key: $DATASET_KEY"
echo ""

# Run the R script using Windows Rscript
Rscript.exe "$SCRIPT_DIR/compare_versions_precheck.R" "$DATASET_KEY"
