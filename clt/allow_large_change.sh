#!/bin/bash

# Script to handle large change in occurrence records
# This script will:
# 1. Allow failed IDs
# 2. Close the issue
# 3. Force re-crawl the dataset

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

uuid=$1

if [ -z "$uuid" ]; then
    echo "Error: No dataset UUID provided"
    exit 1
fi

echo "Processing dataset: $uuid"
echo "================================"

# Change to project root
cd "$PROJECT_ROOT"

# Get the issue number
issue=$(gh issue list --search "is:issue is:open label:$uuid" | awk '{print $1}')

if [ -z "$issue" ]; then
    echo "Error: No open issue found for dataset $uuid"
    exit 1
fi

echo "Found issue #$issue"

# Step 1: Allow failed IDs
echo ""
echo "Step 1: Allowing failed IDs..."
echo "================================"

DATASET_KEY=$(
    gh issue view $issue --json labels | 
    jq '.labels[].name' | 
    grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
    grep -vE 'pub:|inst:' | 
    tr -d '"'
)

if [ -z "$DATASET_KEY" ]; then
    echo "Error: Could not extract dataset key from issue"
    exit 1
fi

echo "Dataset key: $DATASET_KEY"

# Make the API call to allow failed IDs
response=$(curl -s -w "\n%{http_code}" -X POST -u "$GBIF_USER:$GBIF_PWD" \
    -H "Content-Type:application/json" -d '' \
    "https://api.gbif.org/v1/pipelines/history/identifier/$DATASET_KEY/allow")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 204 ]; then
    echo "✅ Successfully allowed failed IDs"
    gh issue edit $issue --add-label "occurrenceID - resumes ingestion with new"
else
    echo "⚠️  API call returned status code: $http_code"
    echo "Response: $body"
fi

# Step 2: Close the issue
echo ""
echo "Step 2: Closing issue..."
echo "================================"
gh issue close $issue
echo "✅ Closed issue #$issue"

# Step 3: Force re-crawl
echo ""
echo "Step 3: Force re-crawl the dataset"
echo "================================"
echo "Run the following commands on the crawler server:"
echo ""
echo " / \\__"
echo "(    @\\___"
echo " /         O"
echo "/   (_____/"
echo "/_____/   U"
echo ""
echo "sudo -u crap -i <<EOF"
echo "cd ~/util"
echo "./recrawl --clean-archive --clean-zk --recrawl $uuid"
echo "EOF"
echo ""
echo " / \\__"
echo "(    @\\___"
echo " /         O"
echo "/   (_____/"
echo "/_____/   U"
echo ""

read -p "Press Enter to SSH to prodcrawler1 (or Ctrl+C to skip)..."
ssh -t jwaller@prodcrawler1-vh.gbif.org

echo ""
echo "================================"
echo "✅ Process complete for dataset $uuid"
echo "================================"
