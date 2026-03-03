#!/bin/bash
# eval `ssh-agent -s`
# ssh-add

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

current_date=$(date '+%Y-%m-%d')
three_months_ago=$(date -d "$current_date -6 months" '+%Y-%m-%d')
echo "Current date: $current_date"
echo "6 months ago: $three_months_ago"

echo 'is:issue created:<$three_months_ago is:open label:contacted'
search="is:issue created:<$three_months_ago assignee:jhnwllr is:open label:contacted -label:\"keep-paused\""
# echo 'is:issue created:<$three_months_ago assignee:jhnwllr is:open label:contacted'
# search="is:issue created:<$three_months_ago is:open label:contacted"
"$SCRIPT_DIR/skip_checks_all_datasets.sh" "$search"	
