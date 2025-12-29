#!/usr/bin/env bash
# Ulauncher configuration for macOS-like Spotlight behavior
# This script sets up Ulauncher with GNOME/GTK integration and configurations for macOS-like appearance

# Create directories if not already present
mkdir -p "$HOME/.config/ulauncher" 2>/dev/null || true

# Set Ulauncher preferences via gsettings (works with Flatpak)
gsettings set com.github.ulauncher.Ulauncher show-indicator false
gsettings set com.github.ulauncher.Ulauncher hotkey-show-app '<Primary>space'
gsettings set com.github.ulauncher.Ulauncher hide-on-focus-lost true
gsettings set com.github.ulauncher.Ulauncher show-recent-apps false
gsettings set com.github.ulauncher.Ulauncher clear-previous-query true
gsettings set com.github.ulauncher.Ulauncher theme-name 'dark'

# Configure GTK theme for macOS-like appearance (Cinnamon compatible)
gsettings set org.cinnamon.desktop.interface gtk-theme 'WhiteSur-dark'
gsettings set org.cinnamon.desktop.interface icon-theme 'WhiteSur'
gsettings set org.cinnamon.desktop.interface cursor-theme 'White-cursor'
gsettings set org.cinnamon.desktop.interface font-name 'Noto Sans 11'

# Enable dark mode preference
gsettings set org.cinnamon.desktop.interface color-scheme 'prefer-dark'

# Add to startup applications
gsettings set org.gnome.desktop.session.legacy.auto-start-enabled true

echo "✅ Ulauncher configured for macOS-like behavior"
echo "✅ Spotlight-like activation: Ctrl+Space"
echo "✅ Dark theme with WhiteSur icon pack"
echo "✅ Auto-hide when focus is lost"