#!/bin/sh

# Alpine Linux Sway + Polybar Setup Script with Belgian locale

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root"
    exit 1
fi

# Set Belgian locale
echo "Setting Belgian locale..."
apk add locales
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "LC_TIME=en_BE.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "en_BE.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# Install required packages
echo "Installing Polybar and dependencies..."
apk add polybar font-awesome ttf-dejavu \
    ttf-font-awesome ttf-hack \
    ttf-ubuntu-font-family \
    playerctl pulseaudio-utils

# Remove swaybar (default bar)
echo "Removing swaybar from Sway config..."
if [ -f /etc/sway/config ]; then
    sed -i '/swaybar_command/d' /etc/sway/config
elif [ -f ~/.config/sway/config ]; then
    sed -i '/swaybar_command/d' ~/.config/sway/config
else
    echo "Could not find Sway config file. You'll need to manually remove swaybar."
fi

# Create Polybar config directory
echo "Creating Polybar config directory..."
mkdir -p ~/.config/polybar

# Create basic Polybar config with Belgian time format
echo "Creating basic Polybar config with Belgian settings..."
cat > ~/.config/polybar/config.ini << 'EOF'
[colors]
background = #2f343f
background-alt = #404552
foreground = #f3f4f5
foreground-alt = #676E7D
primary = #5294e2
secondary = #e53935
alert = #ff5555

[bar/main]
width = 100%
height = 24
offset-x = 0
offset-y = 0
radius = 0.0
fixed-center = true
background = ${colors.background}
foreground = ${colors.foreground}
line-size = 2
line-color = #f00
border-size = 0
border-color = #00000000
padding-left = 1
padding-right = 1
module-margin-left = 1
module-margin-right = 1
font-0 = "DejaVu Sans:size=10;1"
font-1 = "Font Awesome 6 Free:style=Solid:size=10;1"
font-2 = "Font Awesome 6 Brands:size=10;1"
modules-left = sway-workspaces
modules-center = sway-window
modules-right = pulseaudio memory cpu temperature date
tray-position = right
tray-padding = 2

[module/sway-workspaces]
type = internal/sway-workspaces
pin-workspaces = true
enable-click = true
enable-scroll = true
ws-icon-0 = 1;1
ws-icon-1 = 2;2
ws-icon-2 = 3;3
ws-icon-3 = 4;4
ws-icon-4 = 5;5
ws-icon-default = %index%

[module/sway-window]
type = internal/sway-window
format = <label>
label = %title%

[module/pulseaudio]
type = internal/pulseaudio
format-volume = <label-volume> <bar-volume>
label-volume = %percentage%%
label-volume-foreground = ${root.foreground}
label-muted = 🔇 muted
label-muted-foreground = #666
bar-volume-width = 10
bar-volume-foreground-0 = #55aa55
bar-volume-foreground-1 = #55aa55
bar-volume-foreground-2 = #55aa55
bar-volume-foreground-3 = #55aa55
bar-volume-foreground-4 = #55aa55
bar-volume-foreground-5 = #f5a70a
bar-volume-foreground-6 = #ff5555
bar-volume-gradient = false
bar-volume-indicator = |
bar-volume-fill = |
bar-volume-empty = |

[module/memory]
type = internal/memory
interval = 2
format-prefix = "RAM "
format-prefix-foreground = ${colors.foreground-alt}
label = %percentage_used%%

[module/cpu]
type = internal/cpu
interval = 2
format-prefix = "CPU "
format-prefix-foreground = ${colors.foreground-alt}
label = %percentage%%

[module/temperature]
type = internal/temperature
thermal-zone = 0
warn-temperature = 60
format = <ramp> <label>
format-warn = <ramp> <label-warn>
label = %temperature-c%
label-warn = %temperature-c%
label-warn-foreground = ${colors.secondary}
ramp-0 = 🌡

[module/date]
type = internal/date
interval = 1
date = %d/%m/%Y  # Belgian date format (day/month/year)
time = %H:%M:%S
format-prefix = 
format-prefix-foreground = ${colors.foreground-alt}
label = %date% %time%
EOF

# Create Polybar launch script
echo "Creating Polybar launch script..."
cat > ~/.config/polybar/launch.sh << 'EOF'
#!/bin/sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar with Belgian locale
LANG=en_US.UTF-8 LC_TIME=en_BE.UTF-8 polybar main &
EOF

# Make the launch script executable
chmod +x ~/.config/polybar/launch.sh

# Add Polybar to Sway config
echo "Adding Polybar to Sway config..."
if [ -f /etc/sway/config ]; then
    CONFIG_FILE="/etc/sway/config"
elif [ -f ~/.config/sway/config ]; then
    CONFIG_FILE=~/.config/sway/config
else
    echo "Could not find Sway config file. You'll need to manually add Polybar."
    exit 1
fi

# Check if polybar is already in config
if ! grep -q "exec_always ~/.config/polybar/launch.sh" "$CONFIG_FILE"; then
    echo "" >> "$CONFIG_FILE"
    echo "# Start Polybar" >> "$CONFIG_FILE"
    echo "exec_always ~/.config/polybar/launch.sh" >> "$CONFIG_FILE"
fi

# Set environment variables for Belgian locale in Sway config
if ! grep -q "export LANG=en_US.UTF-8" "$CONFIG_FILE"; then
    echo "" >> "$CONFIG_FILE"
    echo "# Set Belgian locale" >> "$CONFIG_FILE"
    echo "export LANG=en_US.UTF-8" >> "$CONFIG_FILE"
    echo "export LC_TIME=en_BE.UTF-8" >> "$CONFIG_FILE"
fi

echo "Setup complete!"
echo "You may need to log out and back in or restart Sway for changes to take effect."
echo "Belgian locale (en_BE) has been configured with date format DD/MM/YYYY."