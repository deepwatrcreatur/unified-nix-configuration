# Set launchctl file descriptor limits
echo "Setting launchctl file descriptor limits..."
/bin/launchctl limit maxfiles 65536 200000 2>/dev/null || true