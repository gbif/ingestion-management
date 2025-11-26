#!/bin/bash
# eval `ssh-agent -s`
# ssh-add

starting_dir=$(pwd)

# Change to project root (relative to this script)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

# gh issue list --search "is:issue" --limit 2000

ALL_DATASET_KEYS=""
while read issue; do 
	DATASET_KEY=$(gh issue view "$issue" --json labels | 
	jq '.labels[].name' | 
	grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
	grep -vE 'pub:|inst:' | 
	tr -d '"'
	)	
	ALL_DATASET_KEYS+="$DATASET_KEY "
done < <(gh issue list --search 'is:closed label:"occurrenceID - resumes ingestion with new"' --limit 1000 | awk '{print $1}')

echo "occurrenceID - resumes ingestion with new"
echo "$ALL_DATASET_KEYS" | tr ' ' '\n'


ALL_DATASET_KEYS=""
while read issue; do 
	DATASET_KEY=$(gh issue view "$issue" --json labels | 
	jq '.labels[].name' | 
	grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
	grep -vE 'pub:|inst:' | 
	tr -d '"'
	)	
	ALL_DATASET_KEYS+="$DATASET_KEY "
done < <(gh issue list --search 'is:closed label:"occurrenceID - migrated"' --limit 1000 | awk '{print $1}')

echo "occurrenceID - migrated"
echo "$ALL_DATASET_KEYS" | tr ' ' '\n'


ALL_DATASET_KEYS=""
while read issue; do 
	DATASET_KEY=$(gh issue view "$issue" --json labels | 
	jq '.labels[].name' | 
	grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
	grep -vE 'pub:|inst:' | 
	tr -d '"'
	)	
	ALL_DATASET_KEYS+="$DATASET_KEY "
done < <(gh issue list --search 'is:closed label:"occurrenceID - publisher changed back"' --limit 1000 | awk '{print $1}')

echo "occurrenceID - publisher changed back"
echo "$ALL_DATASET_KEYS" | tr ' ' '\n'



ALL_DATASET_KEYS=""
while read issue; do 
	DATASET_KEY=$(gh issue view "$issue" --json labels | 
	jq '.labels[].name' | 
	grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
	grep -vE 'pub:|inst:' | 
	tr -d '"'
	)	
	ALL_DATASET_KEYS+="$DATASET_KEY "
done < <(gh issue list --search 'is:closed label:"occurrenceID - large change in record counts"' --limit 1000 | awk '{print $1}')

echo "occurrenceID - large change in record counts"
echo "$ALL_DATASET_KEYS" | tr ' ' '\n'







