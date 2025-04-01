#!/bin/bash

# Function to display the menu
show_menu() {
    echo "Available scripts:"
    for file in *.sh; do
        # Extract the number and name from the filename
        if [[ $file =~ ^([0-9]+)_(.*)\.sh$ ]]; then
            number=${BASH_REMATCH[1]}
            name=${BASH_REMATCH[2]}
            echo "$number) $name"
        fi
    done
    echo "q) Exit"
}

# Function to execute the selected script
execute_script() {
    read -p "Choose a number to execute the script or 'q' to exit: " choice
    if [[ $choice == "q" ]]; then
        echo "Exiting..."
        exit 0
    fi

    # Find the script corresponding to the chosen number
    for file in *.sh; do
        if [[ $file =~ ^([0-9]+)_(.*)\.sh$ ]]; then
            number=${BASH_REMATCH[1]}
            if [[ $number == $choice ]]; then
                echo "Executing $file..."
                bash "$file"
                return
            fi
        fi
    done
    echo "Invalid choice. Please try again."
}

# Main loop to show the menu and execute scripts
while true; do
    show_menu
    execute_script
done
