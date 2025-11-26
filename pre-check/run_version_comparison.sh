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

# Run the R script and capture output
OUTPUT=$(Rscript "$SCRIPT_DIR/compare_versions_precheck.R" "$DATASET_KEY" 2>&1)
EXIT_CODE=$?

# Print the output
echo "$OUTPUT"

# Extract key metrics from output for GitHub Actions
STATUS=$(echo "$OUTPUT" | grep "^STATUS=" | cut -d= -f2)
IPT_RECORDS=$(echo "$OUTPUT" | grep "^IPT_RECORDS=" | cut -d= -f2)
GBIF_RECORDS=$(echo "$OUTPUT" | grep "^GBIF_RECORDS=" | cut -d= -f2)
IPT_VERSION=$(echo "$OUTPUT" | grep "^IPT_VERSION=" | cut -d= -f2)
LAST_MODIFIED_BY=$(echo "$OUTPUT" | grep "^LAST_MODIFIED_BY=" | cut -d= -f2)
OVERLAP_PCT=$(echo "$OUTPUT" | grep "^OVERLAP_PCT=" | cut -d= -f2)
HAS_DUPLICATES=$(echo "$OUTPUT" | grep "^HAS_DUPLICATES=" | cut -d= -f2)
RECORD_DIFF=$(echo "$OUTPUT" | grep "^RECORD_DIFF=" | cut -d= -f2)
RECORD_DIFF_PCT=$(echo "$OUTPUT" | grep "^RECORD_DIFF_PCT=" | cut -d= -f2)
HAS_LARGE_RECORD_CHANGE=$(echo "$OUTPUT" | grep "^HAS_LARGE_RECORD_CHANGE=" | cut -d= -f2)

# Output for GitHub Actions
if [ -n "$STATUS" ]; then
    echo "STATUS=$STATUS" >> $GITHUB_OUTPUT || true
fi
if [ -n "$IPT_RECORDS" ]; then
    echo "IPT_RECORDS=$IPT_RECORDS" >> $GITHUB_OUTPUT || true
fi
if [ -n "$GBIF_RECORDS" ]; then
    echo "GBIF_RECORDS=$GBIF_RECORDS" >> $GITHUB_OUTPUT || true
fi
if [ -n "$IPT_VERSION" ]; then
    echo "IPT_VERSION=$IPT_VERSION" >> $GITHUB_OUTPUT || true
fi
if [ -n "$LAST_MODIFIED_BY" ]; then
    echo "LAST_MODIFIED_BY=$LAST_MODIFIED_BY" >> $GITHUB_OUTPUT || true
fi
if [ -n "$OVERLAP_PCT" ]; then
    echo "OVERLAP_PCT=$OVERLAP_PCT" >> $GITHUB_OUTPUT || true
fi
if [ -n "$HAS_DUPLICATES" ]; then
    echo "HAS_DUPLICATES=$HAS_DUPLICATES" >> $GITHUB_OUTPUT || true
fi
if [ -n "$RECORD_DIFF" ]; then
    echo "RECORD_DIFF=$RECORD_DIFF" >> $GITHUB_OUTPUT || true
fi
if [ -n "$RECORD_DIFF_PCT" ]; then
    echo "RECORD_DIFF_PCT=$RECORD_DIFF_PCT" >> $GITHUB_OUTPUT || true
fi
if [ -n "$HAS_LARGE_RECORD_CHANGE" ]; then
    echo "HAS_LARGE_RECORD_CHANGE=$HAS_LARGE_RECORD_CHANGE" >> $GITHUB_OUTPUT || true
fi

exit $EXIT_CODE
