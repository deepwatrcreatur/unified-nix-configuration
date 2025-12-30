#!/usr/bin/env bash

gsettings set org.mate.panel.toplevels:/org/mate/panel/toplevels/top/ auto-hide 'true'
gsettings set org.mate.panel.toplevels:/org/mate/panel/toplevels/top/ auto-hide-size '1'
gsettings set org.mate.panel.toplevels:/org/mate/panel/toplevels/top/ hide-delay '300'
gsettings set org.mate.panel.toplevels:/org/mate/panel/toplevels/top/ show-delay '500'
gsettings set org.mate.panel.toplevels:/org/mate/panel/toplevels/top/ size '24'

gsettings set org.mate.marco.workspace-names "['Main']"
gsettings set org.mate.marco.general num-workspaces '1'

gsettings set org.mate.marco.general focus-mode 'click'
gsettings set org.mate.marco.general auto-raise 'false'
gsettings set org.mate.marco.general raise-on-click 'true'

gsettings set org.mate.marco.general button-layout 'close,minimize,maximize:'

gsettings set org.mate.marco.general compositing-manager 'true'
gsettings set org.mate.marco.general compositing-fast-alt-tab 'true'

gsettings set org.mate.marco.window-effects minimize 'scale'
gsettings set org.mate.marco.window-effects unminimize 'scale'
gsettings set org.mate.marco.window-effects close 'fade'

gsettings set org.mate.panel.general enable-slab 'false'
gsettings set org.mate.panel.general tooltips-enabled 'true'

gsettings set org.mate.desktop.session idle-delay '0'

gsettings set org.mate.desktop.peripherals.mouse cursor-theme 'capitaine-cursors'
gsettings set org.mate.desktop.peripherals.mouse cursor-size '24'

gsettings set org.mate.desktop.interface gtk-theme 'WhiteSur-Dark'
gsettings set org.mate.desktop.interface icon-theme 'WhiteSur'
gsettings set org.mate.desktop.interface font-name 'Noto Sans 11'

gsettings set org.mate.marco.general theme 'WhiteSur-Dark'

echo "✅ MATE configured for macOS-like behavior"
echo "✅ Auto-hide panel enabled (24px height)"
echo "✅ Single workspace mode (macOS style)"
echo "✅ Window controls moved to left side"
echo "✅ Compositor enabled for transparency"
echo "✅ WhiteSur theme applied"