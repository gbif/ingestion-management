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

# Run the R script - capture both stdout and the exit code
set +e  # Don't exit on error
Rscript "$SCRIPT_DIR/compare_versions_precheck.R" "$DATASET_KEY" 2>&1 | tee /tmp/r_output.txt
R_EXIT_CODE=${PIPESTATUS[0]}
set -e

# Extract metrics from output and write to GITHUB_OUTPUT
if [ -f /tmp/r_output.txt ]; then
    grep "^STATUS=" /tmp/r_output.txt | cut -d= -f2 | xargs -I {} echo "STATUS={}" >> $GITHUB_OUTPUT || true
    grep "^IPT_RECORDS=" /tmp/r_output.txt | cut -d= -f2 | xargs -I {} echo "IPT_RECORDS={}" >> $GITHUB_OUTPUT || true
    grep "^GBIF_RECORDS=" /tmp/r_output.txt | cut -d= -f2 | xargs -I {} echo "GBIF_RECORDS={}" >> $GITHUB_OUTPUT || true
    grep "^IPT_VERSION=" /tmp/r_output.txt | cut -d= -f2 | xargs -I {} echo "IPT_VERSION={}" >> $GITHUB_OUTPUT || true
    grep "^LAST_MODIFIED_BY=" /tmp/r_output.txt | cut -d= -f2 | xargs -I {} echo "LAST_MODIFIED_BY={}" >> $GITHUB_OUTPUT || true
    grep "^OVERLAP_PCT=" /tmp/r_output.txt | cut -d= -f2 | xargs -I {} echo "OVERLAP_PCT={}" >> $GITHUB_OUTPUT || true
    grep "^HAS_DUPLICATES=" /tmp/r_output.txt | cut -d= -f2 | xargs -I {} echo "HAS_DUPLICATES={}" >> $GITHUB_OUTPUT || true
    grep "^RECORD_DIFF=" /tmp/r_output.txt | cut -d= -f2 | xargs -I {} echo "RECORD_DIFF={}" >> $GITHUB_OUTPUT || true
    grep "^RECORD_DIFF_PCT=" /tmp/r_output.txt | cut -d= -f2 | xargs -I {} echo "RECORD_DIFF_PCT={}" >> $GITHUB_OUTPUT || true
    grep "^HAS_LARGE_RECORD_CHANGE=" /tmp/r_output.txt | cut -d= -f2 | xargs -I {} echo "HAS_LARGE_RECORD_CHANGE={}" >> $GITHUB_OUTPUT || true
    rm /tmp/r_output.txt
fi

# Always exit 0 so the workflow step succeeds and outputs are available
exit 0
