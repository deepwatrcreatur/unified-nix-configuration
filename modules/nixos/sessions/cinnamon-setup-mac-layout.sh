#!/usr/bin/env bash
# Cinnamon Multi-Panel Configuration Script for macOS-Like Layout
# This script sets up:
# - Workspace Switcher panel in top-left
# - Status/Tray panel in top-right
# - Plank dock at bottom (handled by systemd service)

set -e

echo "🍎 Configuring Cinnamon for macOS-like multi-panel layout..."

# Backup existing configuration
BACKUP_DIR="$HOME/.cinnamon-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$HOME/.cinnamon/configs/" "$BACKUP_DIR/" 2>/dev/null || echo "No existing config to backup"
echo "✓ Configuration backed up to: $BACKUP_DIR"

# Get the panel ID (usually 1 for default panel)
PANEL_ID=$(dconf read /org/cinnamon/enabled-panels | grep -oP '"id": \K\w+' | head -1)

echo "✓ Using panel ID: $PANEL_ID"

# Configure main panel (top panel)
echo "📝 Configuring main panel (top)..."
dconf write /org/cinnamon/panels-enabled "[{'id': 'panel1', 'location': 'top'}]"

# Create workspace switcher panel (top-left)
echo "📝 Creating workspace switcher panel (top-left)..."
dconf write /org/cinnamon/panels-enabled \
  "[{'id': 'panel1', 'location': 'top'},
    {'id': 'panel2', 'location': 'top', 'left': 0, 'right': 400, 'top': 0, 'bottom': 30, 'monitor': 0, 'size': 30}]"

# Create status/tray panel (top-right)
echo "📝 Creating status/tray panel (top-right)..."
dconf write /org/cinnamon/panels-enabled \
  "[{'id': 'panel1', 'location': 'top'},
    {'id': 'panel2', 'location': 'top', 'left': 0, 'right': 400, 'top': 0, 'bottom': 30, 'monitor': 0, 'size': 30},
    {'id': 'panel3', 'location': 'top', 'left': 800, 'right': 1920, 'top': 0, 'bottom': 30, 'monitor': 0, 'size': 30}]"

# Configure panel1 (main) - mostly empty for clean look
echo "⚙️  Configuring panel1 (main) settings..."
dconf write /org/cinnamon/panels/panel1/panel-edit-mode false
dconf write /org/cinnamon/panels/panel1/enable-left-box false
dconf write /org/cinnamon/panels/panel1/enable-right-box false

# Configure panel2 (workspace switcher) - top-left
echo "⚙️  Configuring panel2 (workspace) settings..."
dconf write /org/cinnamon/panels/panel2/panel-edit-mode false
dconf write /org/cinnamon/panels/panel2/enable-left-box true
dconf write /org/cinnamon/panels/panel2/enable-right-box false
dconf write /org/cinnamon/panels/panel2/center-horizontal false
dconf write /org/cinnamon/panels/panel2/left-box-size 30

# Configure panel3 (status/tray) - top-right
echo "⚙️  Configuring panel3 (status) settings..."
dconf write /org/cinnamon/panels/panel3/panel-edit-mode false
dconf write /org/cinnamon/panels/panel3/enable-left-box false
dconf write /org/cinnamon/panels/panel3/enable-right-box true
dconf write /org/cinnamon/panels/panel3/right-box-size 30
dconf write /org/cinnamon/panels/panel3/center-horizontal false

# Apply WhiteSur-dark theme for transparency
echo "🎨 Applying WhiteSur-dark theme..."
dconf write /org/cinnamon/desktop/interface/gtk-theme "'WhiteSur-dark'"
dconf write /org/cinnamon/desktop/interface/icon-theme "'WhiteSur'"
dconf write /org/cinnamon/desktop/interface/cursor-theme "'White-cursor'"
dconf write /org/cinnamon/theme/name "'WhiteSur-dark'"

# Set fonts
echo "🔤 Setting fonts..."
dconf write /org/cinnamon/desktop/interface/font-name "'Noto Sans 11'"

echo ""
echo "✅ Cinnamon multi-panel configuration complete!"
echo ""
echo "📋 Layout:"
echo "  • Top-left: Workspace Switcher (30px height)"
echo "  • Top-right: Status/Tray Panel (30px height)"
echo "  • Bottom: Plank Dock (auto-started)"
echo ""
echo "⚠️  To customize further:"
echo "    1. Right-click panel → Panel Settings"
echo "    2. Add/Remove applets as desired"
echo "    3. Adjust panel size, transparency in theme settings"
echo ""
echo "🔄 You may need to:"
echo "    - Logout and login again for full effect"
echo "    - Or press Alt+F2, type 'r' to restart Cinnamon"
echo ""
