# macOS-Like Theming Configuration Guide

This guide explains the macOS-like theming that has been added to various desktop environment session modules.

## What Was Added

### Theme Packages
- **WhiteSur GTK Theme**: macOS BigSur-like theme for GTK applications (supports Cinnamon, GNOME, XFCE, MATE, LXDE)
- **WhiteSur Icon Theme**: Matching icon theme with macOS-style icons
- **Apple Cursor**: macOS-like cursor theme
- **Capitaine Cursors**: Alternative clean cursor theme
- **Arc Theme**: Additional theme that pairs well with macOS styling

### Dock
- **Plank**: macOS-like dock application that starts automatically on login
  - Right-click dock → Preferences to configure (position, icon size, theme, hide behavior)
  - Theme support for various dock styles
  - Can hide when windows overlap (like macOS)

### Fonts
- **Noto Fonts**: Complete font family including CJK support and emoji
- **Fira Code**: Monospace font for coding

### Desktop Environments Enhanced
1. **cinnamon.nix**: Complete macOS-like setup with transparent panel support
2. **garuda-themed-gnome.nix**: WhiteSur theming added alongside existing Garuda themes
3. **xfce.nix**: Enhanced with macOS themes
4. **mate.nix**: Enhanced with macOS themes
5. **lxde.nix**: Enhanced with macOS themes

## How to Apply Themes

### After Rebuilding

After running `sudo nixos-rebuild switch`, the themes will be installed system-wide.

#### Cinnamon
1. Right-click panel → System Settings → Themes
2. Select **WhiteSur-dark** for GTK theme
3. Select **WhiteSur** for Icons
4. Select **White-cursor** for Cursor theme
5. For panel customization:
   - Right-click panel → Panel Settings
   - Set panel position to **Top**
   - Enable **"Center"** option in panel edit mode
   - Use WhiteSur theme panel transparency settings

#### GNOME
Themes are auto-applied via dconf settings. To customize:
```bash
# Set theme manually (if needed)
gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-dark"
gsettings set org.gnome.desktop.interface icon-theme "WhiteSur"
gsettings set org.gnome.desktop.interface cursor-theme "White-cursor"
```

#### XFCE
1. Settings → Appearance
2. Style tab → Select **WhiteSur-dark**
3. Icons tab → Select **WhiteSur**
4. Mouse tab → Select **White-cursor**
5. Configure panel to be centered and transparent in Panel settings

#### MATE
1. System → Preferences → Appearance
2. Theme tab → Select **WhiteSur-dark**
3. Icons tab → Select **WhiteSur**
4. Mouse tab → Select **White-cursor**

#### LXDE
1. LXDE Menu → Desktop Preferences → Appearance
2. GTK+ Theme → Select **WhiteSur-dark**
3. Icon Theme → Select **WhiteSur**
4. Mouse Cursor → Select **White-cursor**

### Plank Dock Configuration

Plank starts automatically. To configure:

```bash
# Open Plank preferences
plank --preferences
```

**Recommended Settings**:
- Position: **Bottom**
- Icon Size: **48-64**
- Alignment: **Center**
- Hide Mode: **Intelligent** (hides when window overlaps)
- Theme: **Default** or **Transparent**
- Show on: **Primary display**

### Ulauncher Configuration

Ulauncher starts hidden. Press **Ctrl+Space** to open it.

```bash
# Open preferences
ulauncher --preferences
```

**Recommended Settings**:
- Theme: **Light** or **Dark** (match WhiteSur theme variant)
- Show Indicator: **Yes**
- Hotkey: **Ctrl+Space**

## Manual Panel Customization

For Cinnamon, to get the centered transparent panel:

1. Right-click panel → Panel → Panel settings
2. In **"Panel edit mode"**, enable panel
3. Drag applets to center your desired layout
4. Enable transparency in the theme settings

Alternatively, install Cinnamon extensions for better panel control:
- Cinnamon Settings
- Transparent Panels (from Cinnamon Spices)
- Panel Settings

## Troubleshooting

### Themes Not Appearing
1. Rebuild system: `sudo nixos-rebuild switch`
2. Logout and login again
3. Check dconf settings: `dconf-editor` and navigate to theme paths

### Plank Not Starting
1. Check if service is enabled: `systemctl --user status plank`
2. Start manually: `systemctl --user start plank`
3. Check logs: `journalctl --user -u plank`

### Cursor Not Changing
1. Check XCURSOR_THEME variable is set correctly
2. Log out and back in
3. In some DEs, use the appearance settings GUI instead

### Font Issues
1. Verify fonts are installed: `fc-list | grep Noto`
2. Clear font cache: `fc-cache -fv`
3. Restart applications

## Additional Customization

### Window Borders and Titlebars
WhiteSur theme applies these automatically. To adjust:
- Use the desktop's System Settings
- Look for "Window Theme" or "Window Decorations" options

### Wallpaper
Use `nitrogen` (included) or your DE's wallpaper setting:
```bash
nitrogen
```

### macOS-like Fonts
WhiteSur theme is designed to work best with:
- System fonts: **Noto Sans** (default)
- Monospace: **Fira Code** (included)

## File Locations

All session files are in: `modules/nixos/sessions/`

- `cinnamon.nix` - Cinnamon DE
- `garuda-themed-gnome.nix` - GNOME with Garuda + WhiteSur
- `xfce.nix` - XFCE DE
- `mate.nix` - MATE DE
- `lxde.nix` - LXDE DE

## Tips for Best macOS-Like Appearance

1. **Panel Position**: Top panel works best for macOS look
2. **Panel Size**: Smaller (24-32px) looks more like macOS
3. **Dock Position**: Bottom centered
4. **Dark Theme**: WhiteSur-dark is more popular and modern
5. **Window Controls**: WhiteSur uses window controls on the right by default (macOS style)
6. **Icons**: WhiteSur icons are designed to match the theme perfectly

## Next Steps

1. Rebuild your system: `sudo nixos-rebuild switch --flake .#<hostname>`
2. Reboot or logout/login to see changes
3. Apply themes using the DE's appearance settings
4. Customize Plank dock to your preference
5. Enjoy your macOS-like desktop!

## Removing or Changing Themes

To remove macOS theming, simply:
1. Remove the corresponding packages from the session file
2. Or comment out the entire theme sections
3. Rebuild: `sudo nixos-rebuild switch --flake .#<hostname>`
4. Select different themes in your DE's appearance settings
