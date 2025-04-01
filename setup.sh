#!/bin/bash

# Function to display menu and execute scripts
display_menu() {
    while true; do
        clear
        echo "Select a script to execute:" 
        echo "---------------------------------"
        
        # Find .sh files and sort them
        scripts=($(ls *.sh 2>/dev/null | grep -v "setup.sh" | sort -V))
        script_count=${#scripts[@]}
        
        if [ $script_count -eq 0 ]; then
            echo "No scripts found."
        else
            for i in "${!scripts[@]}"; do
                script_name="${scripts[$i]%.sh}"
                echo "$((i + 1))) $script_name"
            done
        fi
        
        echo "q) Quit"
        echo "---------------------------------"
        read -p "Enter your choice: " choice

        if [[ "$choice" == "q" ]]; then
            echo "Exiting..."
            exit 0
        elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= script_count )); then
            script="${scripts[$((choice - 1))]}"
            echo "Executing $script..."
            chmod +x "$script"
            "./$script"
            read -p "Press Enter to continue..."
        else
            echo "Invalid choice! Try again."
            sleep 1
        fi
    done
}

display_menu
