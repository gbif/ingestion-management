#!/bin/bash

# how to put this on the PATH
# chmod +x /mnt/c/Users/ftw712/Desktop/scripts/shell/choose_option.sh

# Check if arguments are provided
if [ $# -eq 0 ]; then
    # Default choices if no arguments are provided
    choices=("Option 1" "Option 2" "Option 3" "Enter custom text")
else
    # Use provided arguments as choices
    choices=("$@")
fi

# Function to display the menu and handle user input
choose_option() {
    PS3="Please choose an option (1-${#choices[@]}), or enter any text: "
    select opt in "${choices[@]}"; do
        case $REPLY in
            [1-$(( ${#choices[@]} - 1 ))])
                echo "$opt"
                break
                ;;
            ${#choices[@]})
                read -p "Enter your custom text: " custom_text
                echo "$custom_text"
                break
                ;;
            *)
                if [[ -n $REPLY ]]; then
                    echo "$REPLY"
                    break
                else
                    echo "Invalid option. Please try again."
                fi
                ;;
        esac
    done
}

# Call the function and save the output to a variable
user_choice=$(choose_option)

# Display the saved output
echo $user_choice
