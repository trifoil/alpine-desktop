#!/bin/sh

# Exit on error
set -e

echo "Setting up Polybar for Sway on Alpine Linux..."

# 1. Install required packages
echo "Installing dependencies..."
doas apk add --no-cache \
    polybar \
    sway-ipc \
    jq \
    font-dejavu \
    ttf-font-awesome \
    pulseaudio-utils \
    brightnessctl

# 2. Create config directories
echo "Creating config directories..."
mkdir -p ~/.config/polybar
mkdir -p ~/.config/sway

# 3. Create basic Polybar config
echo "Creating Polybar config..."
cat > ~/.config/polybar/config.ini << 'EOL'
[colors]
background = #222222
background-alt = #444444
foreground = #dfdfdf
primary = #ffb52a
secondary = #e60053
alert = #bd2c40

[bar/top]
monitor = ${env:MONITOR:}
width = 100%
height = 24
offset-x = 0
offset-y = 0
fixed-center = true

background = ${colors.background}
foreground = ${colors.foreground}

modules-left = sway/workspaces
modules-center = sway/window
modules-right = pulseaudio date

[module/sway/workspaces]
type = internal/sway/workspaces
pin-workspaces = true
enable-click = true
enable-scroll = true
ws-icon-0 = 1;一
ws-icon-1 = 2;二
ws-icon-2 = 3;三
ws-icon-3 = 4;四
ws-icon-4 = 5;五

[module/sway/window]
type = internal/sway/window
format = <label>
label = %title%

[module/pulseaudio]
type = internal/pulseaudio
format-volume = <ramp-volume> <label-volume>
label-volume = %percentage%%
ramp-volume-0 = 🔈
ramp-volume-1 = 🔉
ramp-volume-2 = 🔊

[module/date]
type = internal/date
interval = 1
date = %Y-%m-%d %H:%M:%S
label = %date%
EOL

# 4. Create Polybar launch script
echo "Creating launch script..."
cat > ~/.config/polybar/launch.sh << 'EOL'
#!/bin/sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Get monitor name
MONITOR=$(swaymsg -t get_outputs | jq -r '.[0].name')

# Launch Polybar
POLYBAR_IPC_SOCKET=/tmp/polybar-ipc.$USER \
MONITOR=$MONITOR \
polybar -q -c ~/.config/polybar/config.ini top &

echo "Polybar launched..."
EOL

chmod +x ~/.config/polybar/launch.sh

# 5. Modify Sway config
echo "Updating Sway config..."
if [ -f ~/.config/sway/config ]; then
    # Remove existing bar configuration
    sed -i '/^bar {/,/^}/d' ~/.config/sway/config

    # Add Polybar launch command
    if ! grep -q "polybar/launch.sh" ~/.config/sway/config; then
        echo -e "\n# Launch Polybar\nexec_always ~/.config/polybar/launch.sh" >> ~/.config/sway/config
    fi
else
    echo "WARNING: Sway config not found at ~/.config/sway/config"
    echo "You'll need to manually add:"
    echo "exec_always ~/.config/polybar/launch.sh"
fi

echo ""
echo "Polybar setup complete!"
echo "Restart Sway or run: ~/.config/polybar/launch.sh"
