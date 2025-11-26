#!/bin/bash
# eval `ssh-agent -s`
# ssh-add

# Get variables for email 
# uuid="4866657c-a5ee-42ad-a6d5-43c9ab3b8dc0"
# uuid="c12a720a-b381-40ce-9746-7cecb8a7735c"
uuid=$1
echo $uuid
starting_dir=$(pwd)

# Change to project root (relative to this script) instead of hardcoded path
# This makes the script portable and ensures it runs from the repository root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_ROOT"

gh issue list --search "is:issue is:open label:$uuid"

issue=$(gh issue list --search "is:issue is:open label:$uuid" |
awk '{print $1}')

# check if there are other open issues for this dataset 
inst_key=$(gh issue view $issue --json labels | 
jq '.labels[].name' |
grep -E 'inst: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}') 

pub_key=$(gh issue view $issue --json labels | 
jq '.labels[].name' |
grep -E 'pub: [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
) 


n_inst=$(gh issue list --search "is:issue is:open label:$inst_key" | wc -l)
n_pub=$(gh issue list --search "is:issue is:open label:$pub_key" | wc -l)

if [ $n_inst -gt 1 ] || [ $n_pub -gt 1 ]; then
    echo "This datasetKey has other open issues with the same installation."
	gh issue list --search "is:issue is:open label:$inst_key"
    echo "This datasetKey has other open issues with the same publisher."
	gh issue list --search "is:issue is:open label:$pub_key"
fi
cd "$starting_dir"

echo "Going to open ipt page ..."
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	iptpage=$(Rscript -e "rgbif::dataset_identifier('$uuid') |> dplyr::filter(type=='URL') |> dplyr::pull(identifier) |> unique() |> head(1) |> cat()")
	echo $iptpage
	powershell.exe -Command "Start-Process '$iptpage'"
fi


echo "Going to compare ipt version with GBIF"
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then


	while true; do

	echo "Please enter dataset version:"
	read userInput
	Rscript.exe -e "gbifim::compare_versions('$uuid',$userInput)"

    read -p "Do you want to check another version? (y/n): " userInput
    # Check if user wants to quit
    if [[ "$userInput" == "n" || "$userInput" == "q" ]]; then
        echo "DONE"
        break # Exit the loop
    fi
	done

fi

echo "Attempt to generate mappings file?"
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then

	echo "Please enter dataset latest version:"
	read v1
	echo "Please enter dataset previous version:"
	read v2
	cd /mnt/c/Users/ftw712/Desktop/
	Rscript.exe "packages/ingestion-management/align_old_new_ids.R" "$uuid" "$v1" "$v2"
	cd $current_working_dir
 fi

echo "Going to compare manually supplied version with GBIF"
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then

	echo "Please enter link:"
	read link
	
	echo "Please enter occ_file:"
	read occ_file
	
	echo "Please enter sep:"
	read sep
	
	echo "Please enter quote:"
	read quote

	Rscript.exe -e "gbifim::compare_versions('$uuid',ep='$link',occ_file='$occ_file',sep='$sep',quote=$quote)"
	
fi


echo "Going to send email ..."
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	datasettitle=$(Rscript -e "rgbif::dataset_get('$uuid') |> dplyr::pull(title) |> cat()")
	datasetkey=$(Rscript -e "rgbif::dataset_get('$uuid') |> dplyr::pull(key) |> cat()")
	echo $datasettitle
	echo $datasetkey

	# who to send email to? 
	Rscript.exe -e "rgbif::dataset_contact('$uuid') |> dplyr::select(type,email) |> tidyr::unnest(cols=email)"

	emails=$(Rscript -e "rgbif::dataset_contact('$uuid') |> dplyr::pull(email) |> unlist() |> unique() |> cat()")
	IFS=' ' read -r -a choices <<< "$emails"

	# Call the function to display the menu
	user_choice=$(choose_option.sh $emails)

	# Display the saved output
	echo $user_choice
	
	# send email 
	powershell.exe -File 'C:\Users\ftw712\Desktop\scripts\shell\im\send_email.ps1' "$datasettitle" "$datasetkey" "$user_choice"
	echo "Creating draft Email ..." 
fi

echo "Going to send installation digest email ..."
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	starting_dir=$(pwd)
	cd "$PROJECT_ROOT"

	ALL_DATASET_KEYS=""
	while read issue; do 
		echo "$issue"
		DATASET_KEY=$(gh issue view "$issue" --json labels | 
		jq '.labels[].name' | 
		grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
		grep -vE 'pub:|inst:' | 
		tr -d '"'
		)
		HTML="https://www.gbif.org/dataset/$DATASET_KEY"
		ALL_DATASET_KEYS+="$HTML "
	done < <(gh issue list --search "is:issue is:open label:$inst_key" --limit 20 | awk '{print $1}')

	echo "$ALL_DATASET_KEYS"

	# who to send email to? 
	Rscript.exe -e "rgbif::dataset_contact('$uuid') |> dplyr::select(type,email) |> tidyr::unnest(cols=email)"

	emails=$(Rscript -e "rgbif::dataset_contact('$uuid') |> dplyr::pull(email) |> unlist() |> unique() |> cat()")
	IFS=' ' read -r -a choices <<< "$emails"

	# Call the function to display the menu
	user_choice=$(choose_option.sh $emails)

	# Display the saved output
	echo $user_choice
	
	# send email 
	powershell.exe -File 'C:\Users\ftw712\Desktop\scripts\shell\im\send_digest_email.ps1' "$ALL_DATASET_KEYS" "$user_choice"
	echo "Creating draft Email ..." 
	cd $starting_dir
fi


echo "Going to mark the issue as contacted ..."
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	starting_dir=$(pwd)
	cd "$PROJECT_ROOT"
	issue=$(gh issue list --search "is:issue is:open label:$uuid"|
	awk '{print $1}')
	gh issue edit $issue --add-label "Contacted"
	cd "$starting_dir"
fi

echo "Do you want to mark as large change in occurrence records?"
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	starting_dir=$(pwd)
	cd "$PROJECT_ROOT"
	issue=$(gh issue list --search "is:issue is:open label:$uuid"|
	awk '{print $1}')
	gh issue edit $issue --add-label "occurrenceID - large change in record counts"
	cd "$starting_dir"
fi



echo "Do you want to assign to yourself? ..."
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	starting_dir=$(pwd)
	cd "$PROJECT_ROOT"
	issue=$(gh issue list --search "is:issue is:open label:$uuid"|
	awk '{print $1}')
	echo "Assigning $issue to jhnwllr"
	gh issue edit $issue --add-assignee "@me"
	cd "$starting_dir"
fi

echo "Do you want to allow failed ids? ..."
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	starting_dir=$(pwd)
	cd "$PROJECT_ROOT"
	DATASET_KEY=$(
	gh issue view $issue --json labels | 
	jq '.labels[].name' | 
	grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
	grep -vE 'pub:|inst:' | 
	tr -d '"'
	)
	echo "Allowing failed ids ..." 
	curl -i -X POST -u "$GBIF_USER:$GBIF_PWD" -H "Content-Type:application/json" -d '' "https://api.gbif.org/v1/pipelines/history/identifier/$DATASET_KEY/allow"
		gh issue edit $issue --add-label "occurrenceID - resumes ingestion with new"
	cd "$starting_dir"
	
fi

echo "Do you want to close the issue? ..."
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	starting_dir=$(pwd)
	cd "$PROJECT_ROOT"
	gh issue close $issue
	cd "$starting_dir"
fi


echo "Do you want to force re-crawl the dataset? (yes/no)"
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	echo run the following commands between the dog heads
	echo " / \\__"
	echo "(    @\\___"
	echo " /         O"
	echo "/   (_____/"
	echo "/_____/   U"
	echo "sudo -u crap -i <<EOF"
	echo "cd ~/util"
	echo "./recrawl --clean-archive --clean-zk --recrawl $uuid"
	echo "EOF"	
	echo " / \\__"
	echo "(    @\\___"
	echo " /         O"
	echo "/   (_____/"
	echo "/_____/   U"
	ssh -t jwaller@prodcrawler1-vh.gbif.org
fi


echo "Do you want to double check with rgbif::dataset_process? (yes/no)"
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	Rscript.exe -e "rgbif::dataset_process('$uuid') |> purrr::pluck('data') |> head(1) |> dplyr::select(startedCrawling,finishReason)"
fi




