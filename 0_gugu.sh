#!/bin/sh
set -e

echo "🚀 Setting up Polybar for Sway (Alpine Linux)..."

# ===== 1. Install Dependencies =====
echo "📦 Installing dependencies..."
doas apk add polybar 
doas apk add jq 
doas apk add font-dejavu 
doas apk add ttf-font-awesome 
doas apk add pavucontrol       # PulseAudio control (volume)
doas apk add brightnessctl      # Brightness control


# ===== 2. Configure Sway =====
SWAY_CONFIG="${SWAY_CONFIG:-$HOME/.config/sway/config}"
mkdir -p "$(dirname "$SWAY_CONFIG")"

# Create basic Sway config if none exists
if [ ! -f "$SWAY_CONFIG" ]; then
    echo "ℹ️ Creating default Sway config..."
    cat > "$SWAY_CONFIG" << 'EOL'
# Default Sway config with Polybar
set $mod Mod4
bindsym $mod+Return exec foot
bindsym $mod+d exec wmenu-run

# Polybar integration
exec_always ~/.config/polybar/launch.sh
EOL
fi

# ===== 3. Set Up Polybar =====
mkdir -p ~/.config/polybar

# ---- Config File ----
cat > ~/.config/polybar/config.ini << 'EOL'
[colors]
background = #2E3440
foreground = #D8DEE9
primary = #81A1C1
alert = #BF616A

[bar/main]
monitor = ${env:MONITOR}
width = 100%
height = 24
offset-y = 1
background = ${colors.background}
foreground = ${colors.foreground}
line-size = 2
module-margin = 1

modules-left = sway/workspaces
modules-center = sway/window
modules-right = pulseaudio date

[module/sway/workspaces]
type = internal/sway/workspaces
label-focused = %name%
label-focused-background = ${colors.primary}
label-unfocused = %name%

[module/sway/window]
type = internal/sway/window
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
date = %Y-%m-%d %H:%M
label = %date%
EOL

# ---- Launch Script ----
cat > ~/.config/polybar/launch.sh << 'EOL'
#!/bin/sh
# Kill existing instances
killall -q polybar

# Wait until processes exit
while pgrep -x polybar >/dev/null; do sleep 0.5; done

# Get monitor name (fallback to first available)
MONITOR=$(swaymsg -t get_outputs | jq -r '.[0].name' || echo "eDP-1")
export MONITOR

# Launch Polybar
polybar -q main &
EOL
chmod +x ~/.config/polybar/launch.sh

# ===== 4. Update Sway Config =====
if ! grep -q "polybar/launch.sh" "$SWAY_CONFIG"; then
    echo -e "\n# Launch Polybar\nexec_always ~/.config/polybar/launch.sh" >> "$SWAY_CONFIG"
fi

echo "✅ Done! Restart Sway (Mod+Shift+e)."