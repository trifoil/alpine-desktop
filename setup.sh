#!/bin/bash

# Function to display the menu and handle user selection
show_menu() {
    clear
    echo "Available scripts:"
    
    # Find and sort all .sh files with numeric prefixes
    local scripts=()
    for file in [0-9]*_*.sh; do
        [[ -f "$file" ]] || continue  # Ensure it's a regular file
        scripts+=("$file")
    done
    
    # Sort scripts by their numeric prefix
    IFS=$'\n' scripts=($(sort -n <<< "${scripts[*]}"))
    unset IFS
    
    # Display the menu
    for i in "${!scripts[@]}"; do
        filename="${scripts[$i]}"
        # Extract the number and name parts
        num=$(echo "$filename" | sed -E 's/^([0-9]+)_.*\.sh$/\1/')
        name=$(echo "$filename" | sed -E 's/^[0-9]+_(.*)\.sh$/\1/')
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
    if [[ "$choice" == "q" ]]; then
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
    for script in [0-9]*_*.sh; do
        num=$(echo "$script" | sed -E 's/^([0-9]+)_.*\.sh$/\1/')
        if [[ "$num" == "$choice" ]]; then
            found=1
            echo "Executing $script..."
            chmod +x "$script" 2>/dev/null  # Make executable if not already
            ./"$script"
            read -p "Press [Enter] to continue..."
            break
        fi
    done
    
    if [[ "$found" -eq 0 ]]; then
        echo "No script found with number $choice"
        read -p "Press [Enter] to continue..."
    fi
done