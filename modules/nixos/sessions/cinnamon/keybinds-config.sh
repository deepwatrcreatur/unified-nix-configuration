#!/usr/bin/env bash
# macOS-like keybinds configuration for Cinnamon
# Sets up keyboard shortcuts to match macOS behavior

# Set up common macOS keybinds

# Mission Control (Expose equivalent)
gsettings set org.cinnamon.muffin keybindings show-desktop "['<Super>d']"
gsettings set org.cinnamon.muffin keybindings switch-to-workspace-left "['<Super><Control>Left']"
gsettings set org.cinnamon.muffin keybindings switch-to-workspace-right "['<Super><Control>Right']"

# Application switching (Command+Tab equivalent)
gsettings set org.cinnamon.muffin keybindings switch-applications "['<Alt>Tab']"
gsettings set org.cinnamon.muffin keybindings switch-applications-backward "['<Shift><Alt>Tab']"
gsettings set org.cinnamon.muffin keybindings switch-windows "['<Super>Tab']"
gsettings set org.cinnamon.muffin keybindings switch-windows-backward "['<Shift><Super>Tab']"

# Window management
gsettings set org.cinnamon.muffin keybindings close "['<Super>q', '<Alt>F4']"
gsettings set org.cinnamon.muffin keybindings minimize "['<Super>m']"
gsettings set org.cinnamon.muffin keybindings maximize "['<Super>Up']"
gsettings set org.cinnamon.muffin keybindings toggle-maximized "['<Super>Down']"

# Safari-like navigation
gsettings set org.cinnamon.muffin keybindings begin-resize "['<Super>r']"

# Finder-like shortcuts
gsettings set org.cinnamon.muffin keybindings move-to-workspace-left "['<Shift><Super><Control>Left']"
gsettings set org.cinnamon.muffin keybindings move-to-workspace-right "['<Shift><Super><Control>Right']"

# Screenshot (Command+Shift+3/4 equivalents)
gsettings set org.cinnamon.desktop.keybindings.media-keys screenshot "['<Print>']"
gsettings set org.cinnamon.desktop.keybindings.media-keys screenshot-clip "['<Ctrl><Print>']"
gsettings set org.cinnamon.desktop.keybindings.media-keys area-screenshot "['<Alt><Print>']"
gsettings set org.cinnamon.desktop.keybindings.media-keys area-screenshot-clip "['<Ctrl><Alt><Print>']"
gsettings set org.cinnamon.desktop.keybindings.media-keys window-screenshot "['<Shift><Print>']"
gsettings set org.cinnamon.desktop.keybindings.media-keys window-screenshot-clip "['<Ctrl><Shift><Print>']"

# Audio controls (Function keys behavior)
gsettings set org.cinnamon.desktop.keybindings.media-keys volume-up "['XF86AudioRaiseVolume']"
gsettings set org.cinnamon.desktop.keybindings.media-keys volume-down "['XF86AudioLowerVolume']"
gsettings set org.cinnamon.desktop.keybindings.media-keys volume-mute "['XF86AudioMute']"

# Brightness controls
gsettings set org.cinnamon.desktop.keybindings.media-keys brightness-up "['XF86MonBrightnessUp']"
gsettings set org.cinnamon.desktop.keybindings.media-keys brightness-down "['XF86MonBrightnessDown']"

# System controls
gsettings set org.cinnamon.desktop.keybindings.media-keys terminal "['<Super><Alt>t']"
gsettings set org.cinnamon.desktop.keybindings.media-keys help "['F1']"

# Custom keyboard shortcuts for Ulauncher
gsettings set org.cinnamon.desktop.keybindings.custom-keybindings "['/org/cinnamon/desktop/keybindings/customkeys/custom0/']"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/customkeys/custom0/ name "Ulauncher"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/customkeys/custom0/ command "ulauncher-toggle"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom0/ binding "<Primary>space"

echo "✅ macOS-like keybinds configured for Cinnamon"
echo "✅ Command+Tab equivalent: Super+Tab"
echo "✅ Mission Control: Super+Control+Arrow keys"
echo "✅ Window management: Super+Q/M/Up/Down"
echo "✅ Screenshots: Print combinations"
echo "✅ Ulauncher toggle: Ctrl+Space"