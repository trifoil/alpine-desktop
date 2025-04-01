#!/bin/bash

# Function to display menu and execute scripts
display_menu() {
    while true; do
        clear
        echo "Select a script to execute:" 
        echo "---------------------------------"
        local i=1
        declare -A script_map
        
        # Find .sh files and sort them
        for script in $(ls *.sh 2>/dev/null | grep -v "setup.sh" | sort -V); do
            script_name="${script%.sh}"
            script_map[$i]="$script"
            echo "$i) $script_name"
            ((i++))
        done
        
        echo "q) Quit"
        echo "---------------------------------"
        read -p "Enter your choice: " choice

        if [[ "$choice" == "q" ]]; then
            echo "Exiting..."
            exit 0
        elif [[ -n "${script_map[$choice]}" ]]; then
            echo "Executing ${script_map[$choice]}..."
            chmod +x "${script_map[$choice]}"
            "./${script_map[$choice]}"
            read -p "Press Enter to continue..."
        else
            echo "Invalid choice! Try again."
            sleep 1
        fi
    done
}

display_menu