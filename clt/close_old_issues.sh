#!/bin/bash
# eval `ssh-agent -s`
# ssh-add

current_date=$(date '+%Y-%m-%d')
three_months_ago=$(date -d "$current_date -6 months" '+%Y-%m-%d')
echo "Current date: $current_date"
echo "6 months ago: $three_months_ago"

echo 'is:issue created:<$three_months_ago is:open label:contacted'
search="is:issue created:<$three_months_ago assignee:jhnwllr is:open label:contacted"
# echo 'is:issue created:<$three_months_ago assignee:jhnwllr is:open label:contacted'
# search="is:issue created:<$three_months_ago is:open label:contacted"
skip_checks_all_datasets.sh "$search"	
