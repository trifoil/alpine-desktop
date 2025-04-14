#!/bin/sh
set -e

echo "🚀 Setting up Polybar for Sway on Alpine Linux..."

# 1. Install required packages
echo "📦 Installing dependencies..."
doas apk add --no-cache \
    polybar \
    jq \
    font-dejavu \
    ttf-font-awesome \
    pavucontrol \      # PulseAudio control (volume)
    brightnessctl      # Brightness control

# 2. Create config directories
mkdir -p ~/.config/polybar
mkdir -p ~/.config/sway

# 3. Basic Polybar config (Sway-compatible)
cat > ~/.config/polybar/config.ini << 'EOL'
[colors]
background = #222222
foreground = #ffffff

[bar/top]
monitor = ${env:MONITOR}
width = 100%
height = 24
offset-y = 0
background = ${colors.background}
foreground = ${colors.foreground}

modules-left = sway/workspaces
modules-center = sway/window
modules-right = date

[module/sway/workspaces]
type = internal/sway/workspaces
format = <label-state>
label-focused = %name%
label-unfocused = %name%

[module/sway/window]
type = internal/sway/window
format = <label>
label = %title%

[module/date]
type = internal/date
interval = 1
date = %H:%M:%S
label = %date%
EOL

# 4. Launch script (now checks for Sway IPC)
cat > ~/.config/polybar/launch.sh << 'EOL'
#!/bin/sh
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 0.5; done

# Get primary monitor (Alpine + Sway)
MONITOR=$(swaymsg -t get_outputs | jq -r '.[0].name')
export MONITOR

# Start Polybar
polybar -q top &
EOL
chmod +x ~/.config/polybar/launch.sh

# 5. Update Sway config
if [ -f ~/.config/sway/config ]; then
    sed -i '/^bar {/,/^}/d' ~/.config/sway/config  # Remove default bar
    grep -q "polybar/launch.sh" ~/.config/sway/config || \
        echo -e "\n# Launch Polybar\nexec_always ~/.config/polybar/launch.sh" >> ~/.config/sway/config
else
    echo "⚠️ Sway config not found at ~/.config/sway/config"
    echo "Add this line manually:"
    echo "exec_always ~/.config/polybar/launch.sh"
fi

echo "✅ Done! Restart Sway (Mod+Shift+e)."