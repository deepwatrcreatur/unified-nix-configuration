#!/usr/bin/env bash
# macOS-like workspace/dock behavior setup for Cinnamon
# Configures workspace switching, dock behavior, and window management

# Configure Cinnamon settings for macOS-like behavior

# Dock/Panel behavior
gsettings set org.cinnamon panel-autohide 'true'
gsettings set org.cinnamon panel-show-autohide-timer '500'
gsettings set org.cinnamon panel-autohide-delay '300'

# Workspace behavior - macOS like (no overlapping)
gsettings set org.cinnamon workspace-names "['Main']"
gsettings set org.cinnamon number-of-workspaces '1'
gsettings set org.cinnamon workspace-cycle 'false'

# Window management - macOS style
gsettings set org.cinnamon.muffin edge-tiling 'false'
gsettings set org.cinnamon.muffin dynamic-workspaces 'false'
gsettings set org.cinnamon.muffin workspace-cycle 'false'

# Alt-Tab behavior (Command-Tab equivalent)
gsettings set org.cinnamon alttab-switcher-style 'icons'
gsettings set org.cinnamon alttab-switcher-show 'all-windows'
gsettings set org.cinnamon window-effect-close 'fade'
gsettings set org.cinnamon window-effect-minimize 'scale'
gsettings set org.cinnamon window-effect-unminimize 'scale'

# Applet management - place key applets like macOS
gsettings set org.cinnamon enabled-applets "['panel1:left:0:menu@cinnamon.org', 'panel1:left:1:show-desktop@cinnamon.org', 'panel1:left:2:window-list@cinnamon.org', 'panel1:right:0:keyboard@cinnamon.org', 'panel1:right:1:settings@cinnamon.org', 'panel1:right=2:power@cinnamon.org']"

# Hot corners - similar to macOS Mission Control
gsettings set org.cinnamon overview-corner 'true'
gsettings set org.cinnamon hotcorner-layout "[{'x': 1.0, 'y': 0.0, 'command': 'expo'}, {'x': 0.0, 'y': 1.0, 'command': 'desktop'}]"

# Window controls (close, minimize, maximize) on left side like macOS
gsettings set org.cinnamon.muffin button-layout 'close,minimize,maximize:'

# Focus behavior
gsettings set org.cinnamon.muffin focus-mode 'click'
gsettings set org.cinnamon.muffin auto-raise 'false'
gsettings set org.cinnamon.muffin raise-on-click 'true'

echo "✅ Cinnamon configured for macOS-like behavior"
echo "✅ Auto-hide panel enabled"
echo "✅ Single workspace mode (macOS style)"
echo "✅ Window controls moved to left side"
echo "✅ Hot corners configured for Mission Control-like access"