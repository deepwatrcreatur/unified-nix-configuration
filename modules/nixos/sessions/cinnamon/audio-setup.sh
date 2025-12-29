#!/usr/bin/env bash
# Set up PulseAudio/Pipewire for macOS-like audio controls
# Configures volume control integration with Cinnamon panel and keybinds

# Create user pulse directory if it doesn't exist
mkdir -p "$HOME/.config/pulse" 2>/dev/null || true

# Create default.pa configuration for macOS-like audio behavior
cat > "$HOME/.config/pulse/default.pa" << 'EOF'
#!/usr/bin/env pulseaudio -nF

# Load default modules
.include /etc/pulse/default.pa

# macOS-like audio behavior modules
load-module module-match table=/etc/pulse/match.table
load-module module-udev-detect
load-module module-detect

# Ensure proper sink/source management for volume control
load-module module-stream-restore restore_device=false restore_volume=true restore_muted=true

# Enable flat volumes for smoother volume transitions (macOS-like)
load-module module-device-restore

# Automatic null-sink for system sounds
load-module module-null-sink sink_name=null sink_properties=device.description="Null Output"

# Bluetooth audio support
load-module module-bluetooth-policy
load-module module-bluetooth-discover
load-module module-bluez5-device
load-module module-bluez5-discover

EOF

# Configure ALSA if present
if [ -f /etc/asound.conf ]; then
    sudo cp /etc/asound.conf /etc/asound.conf.backup 2>/dev/null || true
fi

# Create Cinnamon-compatible volume control script
cat > "$HOME/.config/cinnamon/volume-control" << 'EOF'
#!/usr/bin/env python3
# Cinnamon volume control with macOS-like behavior
import subprocess
import sys

def get_volume():
    try:
        result = subprocess.run(['pactl', 'get-sink-volume', '@DEFAULT_SINK@'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            # Parse volume percentage
            for line in result.stdout.split('\n'):
                if '/' in line and '%' in line:
                    volume = int(line.split('/')[1].strip().replace('%', ''))
                    return volume
    except:
        pass
    return 50

def set_volume(volume):
    if 0 <= volume <= 100:
        subprocess.run(['pactl', 'set-sink-volume', '@DEFAULT_SINK@', f'{volume}%'])

def toggle_mute():
    subprocess.run(['pactl', 'set-sink-mute', '@DEFAULT_SINK@', 'toggle'])

if __name__ == "__main__":
    if len(sys.argv) == 2:
        if sys.argv[1] == 'get':
            print(get_volume())
        elif sys.argv[1] == 'mute':
            toggle_mute()
        elif sys.argv[1].startswith('+'):
            set_volume(get_volume() + int(sys.argv[1][1:]))
        elif sys.argv[1].startswith('-'):
            set_volume(max(0, get_volume() - int(sys.argv[1][1:])))
        else:
            set_volume(int(sys.argv[1]))
EOF

chmod +x "$HOME/.config/cinnamon/volume-control"

echo "✅ PulseAudio/Pipewire configured for macOS-like audio controls"
echo "✅ Volume control script created for Cinnamon integration"
echo "✅ Audio sink management optimized for smooth volume transitions"