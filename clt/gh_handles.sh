#!/bin/bash
# eval `ssh-agent -s`
# ssh-add
# how to put this on the PATH
# chmod +x /mnt/c/Users/ftw712/Desktop/scripts/shell/migrate_ids.sh

# test search as variable 
# @ktotsum

# github handles auto tagging 
cd /mnt/c/Users/ftw712/Desktop/scripts/shell/ingestion-management

# tag user function which will tag github users with a digest comment 
tag_user () {
search=$1
user=$2
link=$3

echo "relevant variables:"
echo $search
echo $user
echo $link

echo "Do you want to scan the ingestion-management repo for special case tags? ..."
read -p "Do you want to continue? (y/n): " answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then

	gh_search=$(gh issue list --search "$search")
	n_issues=$(gh issue list --search "$search" | wc -l)
	if [ $n_issues -gt 0 ]; then
	echo There $n_issues open $user issues ...
	gh issue list --search "$search"

	echo "Do you want to make an issue digest for $user? ..."
	read -p "Do you want to continue? (y/n): " answer
	answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')

		if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then
			# pick first issue as comment issue 
			c_issue=$(gh issue list --search "$search" --limit 1 | awk '{print $1}')
			echo $c_issue
			gh issue comment $c_issue -b "Hi $user, <br> \
				Could you take a look at this occurrenceId issue? <br> \
				There are also other open issues similar to this one which can be found here : <br> \
				[other issues]($link)"
		fi

	echo "Do you want to assign all issues for $user to yourself? ..."
	read -p "Do you want to continue? (y/n): " answer
	answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
		if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then		
			gh issue list --search "$search" --limit 1000 |
			awk '{print $1}' |
			while read issue; do	 
			echo "Assigning $issue to jhnwllr"
			gh issue edit $issue --add-assignee "@me"
			done
		fi

	echo "Do you want to mark all issues for $user as contacted? ..."
	read -p "Do you want to continue? (y/n): " answer
	answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
		if [ "$answer" != "n" ] && [ "$answer" != "no" ]; then		
			gh issue list --search "$search" --limit 1000 |
			awk '{print $1}' |
			while read issue; do	 
			echo "Marking $issue as Contacted"
			gh issue edit $issue --add-label "Contacted"
			done
		fi
	fi


	
fi
}

# known user tags 
tag_user 'is:issue is:open label:"inst: 82d6992a-b20b-4e74-b6ac-6b971b2c485d" -label:Contacted' '@ktotsum' 'https://github.com/gbif/ingestion-management/issues?q=is%3Aissue+is%3Aopen+label%3A%22inst%3A+82d6992a-b20b-4e74-b6ac-6b971b2c485d%22'
tag_user 'is:open label:"inst: d0709e6e-78bf-49e8-8814-384ac4fb139f" -label:Contacted' '@ClaraBaringoFonseca' 'https://github.com/gbif/ingestion-management/issues?q=is%3Aopen+label%3A%22inst%3A+d0709e6e-78bf-49e8-8814-384ac4fb139f%22'
tag_user 'is:open label:"Country FRANCE" -label:Contacted' '@SophiePamerlon' 'https://github.com/gbif/ingestion-management/labels/Country%20FRANCE'
		
starting_dir=$(pwd)



# @ktotsum
# is:issue is:open label:"inst: 82d6992a-b20b-4e74-b6ac-6b971b2c485d" -label:Contacted

# @ClaraBaringoFonseca 
# is:open label:"inst: d0709e6e-78bf-49e8-8814-384ac4fb139f" -label:Contacted

# @SophiePamerlon 



# starting_dir=$(pwd)
# cd /mnt/c/Users/ftw712/Desktop/scripts/shell/ingestion-management

# gh issue list --search "is:issue is:open label:$uuid"

# issue=$(gh issue list --search "is:issue is:open label:$uuid"|
# awk '{print $1}')

cd "$starting_dir"






