#!/bin/bash
search=$1

# search should be in single quotes 
# 'is:issue is:open label:"pub: 1928bdf0-f5d2-11dc-8c12-b8a03c50a862"'
echo $search


starting_dir=$(pwd)

# Change to project root (relative to this script)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

read -p "Do you want to check for multi-participant issues? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then

	# gh issue list --repo gbif/ingestion-management --state open --json number,comments \
	gh issue list --repo gbif/ingestion-management --state open --assignee jhnwllr --json number,comments \
	| jq -r '.[] | select(.comments >= 3) | .number' \
	| while read -r issue_number; do
		participants=$(gh api repos/gbif/ingestion-management/issues/"$issue_number"/comments --jq '.[] | .user.login' | sort | uniq | wc -l)
		if [ "$participants" -gt 1 ]; then
			echo "$issue_number"
		fi
	  done
  echo "check if any issues appear below"
fi


gh issue list --search "$search" --limit 1000

ALL_DATASET_KEYS=""
while read issue; do 
	DATASET_KEY=$(gh issue view "$issue" --json labels | 
	jq '.labels[].name' | 
	grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
	grep -vE 'pub:|inst:' | 
	tr -d '"'
	)	
	ALL_DATASET_KEYS+="$DATASET_KEY "
done < <(gh issue list --search "$search" --limit 1000 | awk '{print $1}')

echo "$ALL_DATASET_KEYS"

# Initialize issue counter
issue_counter=0

# Function to check GitHub API rate limit
check_rate_limit() {
    echo "Checking GitHub API rate limit..."
    rate_limit_response=$(gh api rate_limit)
    
    # Extract GraphQL remaining requests
    graphql_remaining=$(echo "$rate_limit_response" | jq -r '.resources.graphql.remaining')
    
    echo "GraphQL remaining: $graphql_remaining"
    
    # If remaining requests are less than 100, pause for 1 hour 10 minutes
    if [ "$graphql_remaining" -lt 300 ]; then
        echo "GraphQL rate limit low ($graphql_remaining remaining). Pausing for 1 hour 10 minutes..."
        sleep 4200  # Sleep for 1 hour 10 minutes (4200 seconds)
        echo "Resuming after rate limit pause..."
    fi
}

# Initial rate limit check
echo "Starting script - checking initial rate limit..."
check_rate_limit

read -p "Do you want allow failed ids for all datasets? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	while read issue; do 
		echo "$issue"
		
		# Increment issue counter and check rate limit every 5 issues
		issue_counter=$((issue_counter + 1))
		if [ $((issue_counter % 5)) -eq 0 ]; then
			check_rate_limit
		fi
		
		DATASET_KEY=$(gh issue view "$issue" --json labels | 
		jq '.labels[].name' | 
		grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
		grep -vE 'pub:|inst:' | 
		tr -d '"'
		)
		# allow failed ids 
		curl -i -X POST -u "$GBIF_USER:$GBIF_PWD" -H "Content-Type:application/json" -d '' "https://api.gbif.org/v1/pipelines/history/identifier/$DATASET_KEY/allow"
		gh issue edit $issue --add-label "occurrenceID - resumes ingestion with new"
	
	done < <(gh issue list --search "$search" --limit 1000 | awk '{print $1}')

fi


read -p "Do you want allow skip id checks for all datasets? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	# Reset issue counter for this block
	issue_counter=0
	while read issue; do 
		echo "$issue"
		
		# Increment issue counter and check rate limit every 5 issues
		issue_counter=$((issue_counter + 1))
		if [ $((issue_counter % 5)) -eq 0 ]; then
			check_rate_limit
		fi
		
		DATASET_KEY=$(gh issue view "$issue" --json labels | 
		jq '.labels[].name' | 
		grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
		grep -vE 'pub:|inst:' | 
		tr -d '"'
		)

	curl -i -X 'POST' -u "$GBIF_USER:$GBIF_PWD" \
	"https://api.gbif.org/v1/dataset/$DATASET_KEY/machineTag" \
	-H 'accept: application/json' \
	-H 'Content-Type: application/json' \
	-d '{
	"namespace": "pipelines.gbif.org",
	"name": "id_threshold_skip",
	"value": "true"
	}'
	
	gh issue edit $issue --add-label "occurrenceID - checks disabled"
	
	done < <(gh issue list --search "$search" --limit 1000 | awk '{print $1}')

fi

read -p "Do you want close all issues for the datasets? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	# Reset issue counter for this block
	issue_counter=0
	while read issue; do 
		echo "$issue"
		
		# Increment issue counter and check rate limit every 5 issues
		issue_counter=$((issue_counter + 1))
		if [ $((issue_counter % 5)) -eq 0 ]; then
			check_rate_limit
		fi
		
		DATASET_KEY=$(gh issue view "$issue" --json labels | 
		jq '.labels[].name' | 
		grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
		grep -vE 'pub:|inst:' | 
		tr -d '"'
		)
	gh issue close $issue
	
	done < <(gh issue list --search "$search" --limit 1000 | awk '{print $1}')

fi

read -p "Do you want to force re-crawl the datasets? (y/n)" answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	echo run the following commands between the dog heads
	echo " / \\__"
	echo "(    @\\___"
	echo " /         O"
	echo "/   (_____/"
	echo "/_____/   U"
	echo sudo -u crap -i 
	echo cd util
	echo ./recrawl --clean-archive --clean-zk --recrawl "$ALL_DATASET_KEYS"
	echo " / \\__"
	echo "(    @\\___"
	echo " /         O"
	echo "/   (_____/"
	echo "/_____/   U"
	ssh -t jwaller@prodcrawler1-vh.gbif.org
fi

gh issue list --search "$search" --limit 1000

