#!/usr/bin/env bash
# Apply macOS-like Cinnamon panel layout
# This script configures the Cinnamon panel for a macOS-like appearance

echo "Configuring Cinnamon panel for macOS-like appearance..."

# Enable panel autohide for all panels
gsettings set org.cinnamon panels-autohide "['1:true', '2:true', '3:true', '4:true']"
gsettings set org.cinnamon panels-hide-delay "['1:300', '2:300', '3:300', '4:300']"
gsettings set org.cinnamon panels-show-delay "['1:500', '2:500', '3:500', '4:500']"

# Configure panel applet layout for macOS-like appearance
# Format: 'panel:zone:position:applet-id:instance-id'
# Zones: left, center, right
# This creates: Menu (left) | Window list (left) | Clock (center) | System tray (right)

gsettings set org.cinnamon enabled-applets "[
  'panel2:left:0:menu@cinnamon.org:0',
  'panel2:left:1:window-list@cinnamon.org:1',
  'panel2:center:0:calendar@cinnamon.org:2',
  'panel2:right:0:systray@cinnamon.org:3',
  'panel2:right:1:notifications@cinnamon.org:4',
  'panel2:right:2:network@cinnamon.org:5',
  'panel2:right:3:sound150@claudiux:6',
  'panel2:right:4:settings@cinnamon.org:7'
]"

# Set panel height (smaller like macOS)
gsettings set org.cinnamon panels-height "['1:40', '2:40', '3:40', '4:40']"

# Disable panel barriers (smoother mouse movement)
gsettings set org.cinnamon no-adjacent-panel-barriers true

echo "✓ Panel layout configured"
echo "✓ Panel autohide enabled"
echo "✓ Panel height set to 40px (macOS-like)"
echo ""
echo "You may need to restart Cinnamon for all changes to take effect:"
echo "  Press Alt+F2, type 'r', and press Enter"
echo "  OR log out and log back in"
