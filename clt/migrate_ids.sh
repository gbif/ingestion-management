#!/bin/bash
eval `ssh-agent -s`
ssh-add

uuid=$1
current_working_dir=$(pwd)

# Change to project root (relative to this script)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "Do you want to check if files are csv? (yes/no)"
read -r user_input

# Convert user input to lowercase
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

if [[ $user_input == "yes" ]] || [[ $user_input == "y" ]]; then
	if awk -F',' '{ if (NF != 2) { exit 1 } }' $uuid; then
    	echo "The file has exactly two columns."
	else
    	echo "The file does not have two columns."
	fi
fi

# how to put this on the PATH
# chmod +x /mnt/c/Users/ftw712/Desktop/scripts/shell/migrate_ids.sh

echo "Do you want to check for duplicates? (yes/no)"
read -r user_input

# Convert user input to lowercase
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

if [[ $user_input == "no" ]] || [[ $user_input == "n" ]]; then
    echo "User chose to continue."
else
    echo "Checking for duplicates..."
    
    # Assuming $uuid is the variable that holds your CSV file name
    cd /mnt/c/Users/ftw712/Desktop/
	Rscript.exe "scripts/shell/im/migrate_ids_check_duplicates.R" "$uuid"
	cd $current_working_dir
fi


echo "Do you want to check migration files ids? (yes/no)"
read -r user_input

# Convert user input to lowercase
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

if [[ $user_input == "no" ]] || [[ $user_input == "n" ]]; then
    echo "User chose to continue."
else
    echo "Checking for migration csv..."
    
	iptpage=$(Rscript -e "rgbif::dataset_identifier('$uuid') |> dplyr::filter(type=='URL') |> dplyr::pull(identifier) |> unique() |> head(1) |> cat()")
	echo $iptpage
	powershell.exe -Command "Start-Process '$iptpage'"

    # Pause for user input
    echo "Please enter latest version number..."
    read -r ipt_version

	echo $ipt_version
	echo $uuid

    # Assuming $uuid is the variable that holds your CSV file name
    cd /mnt/c/Users/ftw712/Desktop/
	Rscript.exe "scripts/shell/im/migrate_ids_check_exist.R" "$uuid" "$ipt_version"
	cd $current_working_dir
fi

################## remove ids not on IPT 

echo "Do you want to remove ids in migration csv that are not on the IPT? (yes/no)" 
read -r user_input

# Convert user input to lowercase
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

if [[ $user_input == "no" ]] || [[ $user_input == "n" ]]; then
    echo "User chose to continue."
else
    echo "Checking for migration csv..."
    
	iptpage=$(Rscript -e "rgbif::dataset_identifier('$uuid') |> dplyr::filter(type=='URL') |> dplyr::pull(identifier) |> unique() |> head(1) |> cat()")
	echo $iptpage
	powershell.exe -Command "Start-Process '$iptpage'"

    # Pause for user input
    echo "Please enter latest version number..."
    read -r ipt_version

	echo $ipt_version
	echo $uuid

    # Assuming $uuid is the variable that holds your CSV file name
    cd /mnt/c/Users/ftw712/Desktop/
	Rscript.exe "scripts/shell/im/migrate_ids_rm_not_on_ipt.R" "$uuid" "$ipt_version"
	cd $current_working_dir
fi


echo "Do you want copy the migrations csv? (yes/no)"
read -r user_input

user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

if [[ $user_input == "no" ]] || [[ $user_input == "n" ]]; then
    echo "User chose to continue."
else
	echo $1
	echo "copying to prodcrawler1-vh"
	scp -r $1 jwaller@prodcrawler1-vh.gbif.org:/home/jwaller/
fi


################# migrate ids 

echo "Do you want to migrate ids? (yes/no)"
read -r user_input
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
if [[ $user_input == "no" ]] || [[ $user_input == "n" ]]; then
    echo "User chose to continue."
else
	echo run the following commands between the cat heads
	echo " /\\_/\\  "
	echo "( o.o ) "
	echo " > ^ < "
	echo sudo -u crap -i 
	echo cd ~crap/util
	echo ./pipelines-gbif-id-migrator -f $1 -t $1 -p /home/jwaller/$1
	echo " /\\_/\\  "
	echo "( o.o ) "
	echo " > ^ < "
	ssh -t jwaller@prodcrawler1-vh.gbif.org
fi

################# re-label 
echo "Do you want to re-label and close the issue? (yes/no)"
read -r user_input

# Convert the input to lowercase
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

# re-label issue
if [[ $user_input == "no" ]] || [[ $user_input == "n" ]]; then
    echo "User chose to continue."
else
    echo "re-labling the issue..."
	current_dir=$(pwd)
	cd "$PROJECT_ROOT"
	gh issue list --search 'is:open label:'$1
	issue=$(gh issue list --search 'is:open label:'$1 | 
	awk '{print $1}')
	echo $issue
	gh issue edit $issue --add-label "occurrenceID - migrated"
	gh issue close $issue
fi

################# re-crawl

echo "Do you want to re-crawl the dataset? (yes/no)"
read -r user_input
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
if [[ $user_input == "no" ]] || [[ $user_input == "n" ]]; then
    echo "User chose to continue."
else
	echo run the following commands between the dog heads
	echo " / \\__"
	echo "(    @\\___"
	echo " /         O"
	echo "/   (_____/"
	echo "/_____/   U"
	echo sudo -u crap -i 
	echo cd util
	echo ./recrawl --clean-archive --clean-zk --recrawl $1
	echo " / \\__"
	echo "(    @\\___"
	echo " /         O"
	echo "/   (_____/"
	echo "/_____/   U"
	ssh -t jwaller@prodcrawler1-vh.gbif.org
fi


################# migrations email

echo "Going to send successful migration email ..."
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
	powershell.exe -File 'C:\Users\ftw712\Desktop\scripts\shell\im\successful_migration_email.ps1' "$datasettitle" "$datasetkey" "$user_choice"
	echo "Creating draft Email ..." 
fi



echo "Going clean up ..."
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	
	cd $current_working_dir
	ls
	
	# rm -f $(ls | grep -E '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
	ls
	echo "migration file removed."
fi

