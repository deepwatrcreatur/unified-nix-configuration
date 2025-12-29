#!/usr/bin/env bash
# Main script to configure macOS-like experience with Cinnamon
# This script orchestrates all configuration components

echo "🍎 Configuring macOS-like experience with Cinnamon..."

# Create necessary directories
mkdir -p "$HOME/.config/cinnamon" 2>/dev/null || true
mkdir -p "$HOME/.config/autostart" 2>/dev/null || true

# Set up Ulauncher (Spotlight equivalent)
echo "⚡ Setting up Ulauncher..."
exec "$HOME/.config/nix-cinnamon-macos/scripts/ulauncher-config.sh"

# Set up audio controls (macOS-like volume behavior)
echo "🔊 Setting up audio controls..."
exec "$HOME/.config/nix-cinnamon-macos/scripts/audio-setup.sh"

# Configure Cinnamon desktop behavior
echo "🖥️  Configuring Cinnamon desktop..."
exec "$HOME/.config/nix-cinnamon-macos/scripts/cinnamon-config.sh"

# Set up macOS-like keyboard shortcuts
echo "⌨️  Configuring keyboard shortcuts..."
exec "$HOME/.config/nix-cinnamon-macos/scripts/keybinds-config.sh"

# Restart Cinnamon to apply all settings
echo "🔄 Restarting Cinnamon..."
cinnamon --replace &

echo "✅ macOS-like Cinnamon configuration complete!"
echo "🚀 Ulauncher: Ctrl+Space (Spotspot-like)"
echo "🎵 Volume controls: Function keys configured"
echo "⌨️  Keybinds: macOS-style shortcuts enabled"
echo "🖥️  Desktop: Auto-hide panel, single workspace"