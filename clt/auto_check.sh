#!/bin/bash
# eval `ssh-agent -s`
# ssh-add

# Get variables for email 
# uuid="4866657c-a5ee-42ad-a6d5-43c9ab3b8dc0"
# uuid="c12a720a-b381-40ce-9746-7cecb8a7735c"
uuid=$1
echo $uuid
starting_dir=$(pwd)

# Change to project root (relative to this script)
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

# get ipt page 
iptpage=$(Rscript -e "rgbif::dataset_identifier('$uuid') |> dplyr::filter(type=='URL') |> dplyr::pull(identifier) |> unique() |> head(1) |> cat()")
echo $iptpage

ipt_version=$(Rscript.exe "C:/Users/ftw712/Desktop/scripts/shell/im/ipt_version_scrape.R" "$uuid")
echo $ipt_version


