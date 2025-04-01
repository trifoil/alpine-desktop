options=(
    "Basic install"
    "Latex full install"
    "Quit" 
)

PS3="Enter a number (1-${#options[@]}): "

select option in "${options[@]}"; do
    case "$REPLY" in 
        1) ./1_basic_install.sh ;;
        2) ./2_latex_install.sh ;;
        q) break ;;
    esac
done