# GNOME Setup Guide - macOS-like Layout

This guide explains how to switch from Cinnamon to GNOME with a macOS-like layout.

## Why GNOME?

**Advantages over Cinnamon:**
- ✅ **Floating dock** - Dash-to-Dock doesn't span full height, auto-sizes to content
- ✅ **Centered dock** - Can be positioned anywhere and centered
- ✅ **More extensions** - Larger ecosystem for customization
- ✅ **Better performance** - More actively developed

**What you'll get:**
- Floating vertical dock on right edge (centered, auto-sizing)
- Top panel with minimal workspace indicator
- Transparent panels and dock (WhiteSur theme)
- macOS-style window controls on left
- All declaratively configured

## How to Switch to GNOME

### 1. Edit Host Configuration

Edit `hosts/nixos/workstation/default.nix`:

```nix
# Comment out Cinnamon:
# ../../../modules/nixos/sessions/cinnamon.nix

# Uncomment GNOME:
../../../modules/nixos/sessions/garuda-themed-gnome.nix
```

### 2. Edit User Configuration

Edit `users/deepwatrcreatur/hosts/workstation/default.nix`:

```nix
imports = [
  ../../default.nix
  ./nh.nix
  ./distrobox.nix

  ../../../../modules/home-manager
  ../../../../modules/home-manager/ghostty
  ../../../../modules/home-manager/just.nix
  ../../../../modules/home-manager/just-nixos.nix
  ../../../../modules/home-manager/gpg-cli.nix
  ../../../../modules/home-manager/zed.nix

  # Comment out Cinnamon:
  # ../../../../modules/home-manager/cinnamon.nix

  # Add GNOME:
  ../../../../modules/home-manager/gnome-whitesur.nix
];
```

### 3. Rebuild

```bash
sudo nixos-rebuild switch --flake .#workstation
```

### 4. Log Out and Select GNOME

1. Log out of your current session
2. At the login screen, click the gear icon
3. Select "GNOME" (not "GNOME on Xorg" - our config forces X11)
4. Log in

## GNOME Configuration

The GNOME setup is fully declarative in `modules/home-manager/gnome-whitesur.nix`:

### Dock Configuration
- **Position**: Right edge, vertically centered
- **Size**: Auto-sizing (doesn't span full height)
- **Transparency**: Dynamic (0.3 opacity)
- **Icons**: 48px with macOS-style running indicators (dots)
- **Behavior**: Click to minimize/preview (macOS-like)

### Panel Configuration
- **Top panel**: Minimal workspace indicator
- **Transparency**: Via Blur My Shell extension
- **Theme**: WhiteSur-Dark

### Window Manager
- **Window controls**: Left side (close, minimize, maximize)
- **Single workspace**: Like macOS
- **Focus mode**: Click

## Extensions Included

1. **Dash-to-Dock** - Floating, auto-sizing dock
2. **Blur My Shell** - Panel and dock transparency
3. **Clipboard Indicator** - Clipboard manager

## Customization

All settings are in `modules/home-manager/gnome-whitesur.nix`. To customize:

1. Edit the file
2. Rebuild: `sudo nixos-rebuild switch --flake .#workstation`
3. Log out and back in

## Switching Back to Cinnamon

Simply reverse the steps - uncomment Cinnamon modules, comment GNOME modules, rebuild, and select Cinnamon at login.

## Troubleshooting

### Extensions not loading
```bash
# Enable extensions manually
gnome-extensions enable dash-to-dock@micxgx.gmail.com
gnome-extensions enable blur-my-shell@aunetx
```

### Dock not appearing
- Log out and back in
- Check extensions are enabled: `gnome-extensions list --enabled`

### X11 vs Wayland
The configuration forces X11 (`wayland = false` in `garuda-themed-gnome.nix`). GNOME will always use X11 with this config.
