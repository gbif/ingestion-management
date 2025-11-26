#!/bin/bash
# new issue scanner 

starting_dir=$(pwd)

# Change to project root (relative to this script)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

gh issue list --search "is:issue is:open -label:Contacted no:assignee" --limit 1

issue=$(gh issue list --search "is:issue is:open -label:Contacted no:assignee" --limit 1 |
awk '{print $1}')

DATASET_KEY=$(gh issue view "$issue" --json labels | 
jq '.labels[].name' | 
grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
grep -vE 'pub:|inst:' | 
tr -d '"'
)

echo $issue
echo $DATASET_KEY

echo "Going to open run report with this issue ..."
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	"$SCRIPT_DIR/report.sh" $DATASET_KEY 
fi

