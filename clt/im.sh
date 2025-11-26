#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "IIIII  M   M"
echo "  I    MM MM"
echo "  I    MM MM"
echo "  I    M M M"
echo "  I    M   M"
echo "  I    M   M"
echo "IIIII  M   M"

echo "Run an ingestion managment script ..."
echo "Select an option:"
echo "1. report"
echo "2. new issue scan"
echo "3. migrate ids"
echo "4. check special github @s"
echo "5. allow failed ids for all datasets in a search"
echo "6. close issues older than 3 months"
echo "7. migrate batch ids"
echo "8. Exit"

read -p "Enter your choice [1-6]: " choice

case $choice in
    1)
        echo "Running report.sh ..."
        echo "Please enter the datasetKey uuid:"
		read uuid	
		"$SCRIPT_DIR/report.sh" $uuid
        ;;
	2)
	echo "Running new_issue_scan.sh ..."
	"$SCRIPT_DIR/new_issue_scan.sh"
	;;			
    3)
        echo "Running Script 2..."
        ls /mnt/c/Users/ftw712/Desktop | grep -E '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'        
        echo "Please enter the datasetKey uuid:"
		read uuid
		"$SCRIPT_DIR/migrate_ids.sh" $uuid
        ;;
    4)
        echo "Running Script 3..."
        "$SCRIPT_DIR/gh_handles.sh"
        ;;
	
	5) echo "Running Script 5..."
	   echo "Please enter the gh search:"
	   read search
	   # search should be in single quotes 'is:issue is:open label:"pub: 1928bdf0-f5d2-11dc-8c12-b8a03c50a862"'
	   echo "$SCRIPT_DIR/skip_checks_all_datasets.sh" "$search"	
	   # "$SCRIPT_DIR/skip_checks_all_datasets.sh" "$search"	
	    ;;

	6) echo "Running Script 6..."
		"$SCRIPT_DIR/close_old_issues.sh"
	    ;;

    7) echo "Running Script 7..."
       bash "$SCRIPT_DIR/migrate_ids_batch.sh"
       ;; 

    8)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option selected."
        exit 1
        ;;
esac
