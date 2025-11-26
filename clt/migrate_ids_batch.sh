#!/bin/bash
# eval `ssh-agent -s`
# ssh-add

# check if there is an issue open for the dataset 

uuid=$1
cd /mnt/c/Users/ftw712/Desktop/batch
current_working_dir=$(pwd)

# Change to project root (relative to this script)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "Do you want to generate Brazil migration files? (yes/no)"
read -r user_input

user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
if [[ $user_input == "yes" ]] || [[ $user_input == "y" ]]; then

  cd "$PROJECT_ROOT"
  gh issue list --state open --limit 1000 --label "Country BRAZIL"
  # "inst: b38ff2b7-c8af-454e-b5af-ee760f0d5bca" 
  ALL_DATASET_KEYS=""
  # Fetch all issues with the specified label and save to a file
  gh issue list --state open --limit 1000 --label "Country BRAZIL" --json labels > issues.json

  # Extract dataset keys from the JSON file
  DATASET_KEYS=$(jq -r '.[].labels[].name' issues.json | 
    grep -P '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | 
    grep -vE 'pub:|inst:' | 
    tr -d '"'
  )
  cd $current_working_dir

  # Iterate over the dataset keys and append them to ALL_DATASET_KEYS
  for DATASET_KEY in $DATASET_KEYS; do
    ALL_DATASET_KEYS+="$DATASET_KEY "
  done

  echo "$ALL_DATASET_KEYS"
  
  # Iterate over each UUID in ALL_DATASET_KEYS
  for uuid in $ALL_DATASET_KEYS; do
    echo "Processing UUID: $uuid"
    ipt_version=$(Rscript.exe "C:/Users/ftw712/Desktop/scripts/shell/im/ipt_version_scrape.R" "$uuid")
    echo "IPT Version: $ipt_version"
    echo "Running R script to generate Brazil migration files..."
    Rscript.exe C:/Users/ftw712/Desktop/scripts/shell/im/brazil_migrations_file_generator.R $uuid $ipt_version
  done

fi

echo "Do you want remove extensions from all files? (yes/no)"
read -r user_input

# Convert user input to lowercase
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
if [[ $user_input == "yes" ]] || [[ $user_input == "y" ]]; then
  for file in *; do
    if [[ $file == *.zip ]]; then
        continue
    fi
    filename="${file%.*}"
    mv "$file" "$filename"
  done
fi


echo "Do you want to check if files are csv? (yes/no)"
read -r user_input

# Convert user input to lowercase
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

if [[ $user_input == "yes" ]] || [[ $user_input == "y" ]]; then
  for file in *; do
    if [[ $file == *.zip ]]; then
        continue
    fi
    echo $file
    if awk -F',' '{ if (NF != 2) { exit 1 } }' $file; then
        echo "The file has exactly two columns."
    else
        echo "The file does not have two columns."
    fi
  done
fi



echo "Do you want remove files without open issues from the batch? (yes/no)"
read -r user_input

user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
if [[ $user_input == "yes" ]] || [[ $user_input == "y" ]]; then

  cd "$PROJECT_ROOT"
  gh issue list --state open --limit 1000

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
  cd $current_working_dir
  for file in *; do
  # Check if the file is in the allowed files array
    if [[ ! " ${ALL_DATASET_KEYS[@]} " =~ " ${file} " ]]; then
      echo "Removing $file"
      # Uncomment the next line to actually remove the file
      rm "$file"
    fi
  done
  echo pwd
fi


echo "Do you want to check all files for duplicates? (yes/no)"
read -r user_input

# Convert user input to lowercase
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

if [[ $user_input == "no" ]] || [[ $user_input == "n" ]]; then
    echo "User chose to continue."
else
    echo "Checking for duplicates..."
      for file in *; do
        if [[ $file == *.zip ]]; then
          continue
        fi
        echo $file 
        Rscript.exe C:/Users/ftw712/Desktop/scripts/shell/im/migrate_ids_check_duplicates.R $file
	  done
fi

echo "Do you want to check migration files ids? (yes/no)"
read -r user_input

user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
if [[ $user_input == "yes" ]] || [[ $user_input == "y" ]]; then
    echo "Checking for migration csv..."
    
    rm -f /mnt/c/Users/ftw712/Desktop/versions.txt
    rm -f /mnt/c/Users/ftw712/Desktop/log.txt

    for uuid in *; do  
      if [[ $uuid == *.zip ]]; then
          continue
      fi
        ipt_version=$(Rscript.exe "C:/Users/ftw712/Desktop/scripts/shell/im/ipt_version_scrape.R" "$uuid")
        iptpage=$(Rscript -e "rgbif::dataset_identifier('$uuid') |> dplyr::filter(type=='URL') |> dplyr::pull(identifier) |> unique() |> head(1) |> cat()")

        echo "START-----------------------------------" >> "/mnt/c/Users/ftw712/Desktop/log.txt"
        echo "Report of migration csv checks" >> "/mnt/c/Users/ftw712/Desktop/log.txt"
        echo "$uuid,$ipt_version,$iptpage" >> "/mnt/c/Users/ftw712/Desktop/log.txt"
        echo "$uuid,$ipt_version,$iptpage"
        output=$(Rscript.exe "C:/Users/ftw712/Desktop/scripts/shell/im/migrate_ids_check_exist.R" "$uuid" "$ipt_version" "TRUE")
        echo $output 
        echo $output >> "/mnt/c/Users/ftw712/Desktop/log.txt"
        echo "END-------------------------------------" >> "/mnt/c/Users/ftw712/Desktop/log.txt"
    done         
fi 


echo "Do you want to clean up the remote dir jhnwllr? (yes/no)"
read -r user_input

user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

if [[ $user_input == "yes" ]] || [[ $user_input == "y" ]]; then

echo run the following commands between the trees
echo "
    *
   ***
  *****
 *******
*********
   |||
"
echo "remove the uuid files from the remote directory"
ssh -t jwaller@prodcrawler1-vh.gbif.org
fi

echo "Do you want copy the migrations csv? (yes/no)"
read -r user_input

user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

if [[ $user_input == "no" ]] || [[ $user_input == "n" ]]; then
    echo "User chose to continue."
else
    ssh "${REMOTE_USER}@${REMOTE_HOST}" "rm -f ${REMOTE_DIR}*"
    
    echo "copying to prodcrawler1-vh"
    for uuid in *; do  
      if [[ $uuid == *.zip ]]; then
          continue
      fi
	    echo $uuid
	    scp -r $uuid jwaller@prodcrawler1-vh.gbif.org:/home/jwaller/
    done         

fi

################# migrate ids 

echo "Do you want to migrate ids? (yes/no)"
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
echo "sudo -u crap -i" 
echo "cd util"
echo "for file in /home/jwaller/*; do"
echo "uuid=\$(basename \"\$file\")"
echo "echo \$uuid"
echo "echo "y" | ./pipelines-gbif-id-migrator -f \$uuid -t \$uuid -p /home/jwaller/\$uuid -s \,"
echo "done"
echo " / \\__"
echo "(    @\\___"
echo " /         O"
echo "/   (_____/"
echo "/_____/   U"         
ssh jwaller@prodcrawler1-vh.gbif.org
fi

# ################# re-label 
echo "Do you want to re-label and close the issue? (yes/no)"
read -r user_input

# Convert the input to lowercase
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

# re-label issue
if [[ $user_input == "yes" ]] || [[ $user_input == "y" ]]; then
	current_dir=$(pwd)
	cd "$PROJECT_ROOT"
    for file in /mnt/c/Users/ftw712/Desktop/batch/*; do  
      uuid=$(basename "$file")
      if [[ $uuid == *.zip ]]; then
        continue
      fi
      echo "re-labling the issue..."
      echo $uuid
      gh issue list --search 'is:open label:'$uuid
      issue=$(gh issue list --search "is:open label:$uuid" --json number --jq '.[0].number')
      echo $issue
      gh issue edit $issue --add-label "occurrenceID - migrated"
      gh issue close $issue
    done         
  cd $current_working_dir
fi


echo "Do you want to re-crawl the dataset? (yes/no)"
read -r user_input
user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')
if [[ $user_input == "yes" ]] || [[ $user_input == "y" ]]; then

  combined_uuid=""
    for file in /mnt/c/Users/ftw712/Desktop/batch/*; do  
      uuid=$(basename "$file")
      if [[ $uuid == *.zip ]]; then
        continue
      fi
      combined_uuid+="$uuid "
    done
  echo $combined_uuid           

	echo run the following commands between the dog heads
	echo " / \\__"
	echo "(    @\\___"
	echo " /         O"
	echo "/   (_____/"
	echo "/_____/   U"
	echo sudo -u crap -i 
	echo cd util
	echo ./recrawl --clean-archive --clean-zk --recrawl $combined_uuid
	echo " / \\__"
	echo "(    @\\___"
	echo " /         O"
	echo "/   (_____/"
	echo "/_____/   U"
	ssh -t jwaller@prodcrawler1-vh.gbif.org
fi

################# migrations email

# echo "Going to send successful migration email ..."
# read -p "Do you want to continue? (y/n): " answer
# answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
# if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
# 	datasettitle=$(Rscript -e "rgbif::dataset_get('$uuid') |> dplyr::pull(title) |> cat()")
# 	datasetkey=$(Rscript -e "rgbif::dataset_get('$uuid') |> dplyr::pull(key) |> cat()")
# 	echo $datasettitle
# 	echo $datasetkey

# 	# who to send email to? 
# 	Rscript.exe -e "rgbif::dataset_contact('$uuid') |> dplyr::select(type,email) |> tidyr::unnest(cols=email)"

# 	emails=$(Rscript -e "rgbif::dataset_contact('$uuid') |> dplyr::pull(email) |> unlist() |> unique() |> cat()")
# 	IFS=' ' read -r -a choices <<< "$emails"

# 	# Call the function to display the menu
# 	user_choice=$(choose_option.sh $emails)

# 	# Display the saved output
# 	echo $user_choice
	
# 	# send email 
# 	powershell.exe -File 'C:\Users\ftw712\Desktop\scripts\shell\im\successful_migration_email.ps1' "$datasettitle" "$datasetkey" "$user_choice"
# 	echo "Creating draft Email ..." 
# fi

# echo "Going clean up ..."
# read -p "Do you want to continue? (y/n): " answer
# answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
# if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
	
# 	cd $current_working_dir
# 	ls
	
# 	# rm -f $(ls | grep -E '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
# 	ls
# 	echo "migration file removed."
# fi

