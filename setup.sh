#!/bin/bash

# Function to display the menu and handle user selection
show_menu() {
    clear
    echo "Available scripts:"
    
    # Find all .sh files with numeric prefixes
    scripts=()
    for file in *.sh; do
        if [[ "$file" =~ ^[0-9]+_ ]]; then
            scripts+=("$file")
        fi
    done
    
    # Sort scripts by their numeric prefix
    IFS=$'\n' sorted=($(sort -n <<< "${scripts[*]}"))
    unset IFS
    
    # Display the menu
    for script in "${sorted[@]}"; do
        num=$(echo "$script" | sed 's/^\([0-9]\+\).*/\1/')
        name=$(echo "$script" | sed 's/^[0-9]\+_\(.*\)\.sh$/\1/')
        echo "$num) $name"
    done
    
    echo "q) Quit"
    echo ""
}

# Main loop
while true; do
    show_menu
    
    read -p "Enter your choice: " choice
    
    # Check if user wants to quit
    if [ "$choice" = "q" ]; then
        echo "Exiting..."
        exit 0
    fi
    
    # Validate the input is a number
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        echo "Invalid input. Please enter a number or 'q' to quit."
        read -p "Press [Enter] to continue..."
        continue
    fi
    
    # Find the corresponding script
    found=0
    for script in *.sh; do
        if [[ "$script" =~ ^$choice ]]; then
            found=1
            echo "Executing $script..."
            chmod +x "$script" 2>/dev/null
            ./"$script"
            read -p "Press [Enter] to continue..."
            break
        fi
    done
    
    if [ "$found" -eq 0 ]; then
        echo "No script found with number $choice"
        read -p "Press [Enter] to continue..."
    fi
done