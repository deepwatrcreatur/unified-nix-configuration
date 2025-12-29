# Desktop Environment Theme Modules

This directory contains Home Manager modules for declarative desktop environment theming with WhiteSur macOS-like theme.

## Overview

The desktop environment theming has been separated into proper Home Manager modules to ensure declarative configuration. Theme settings are applied via Home Manager's `dconf.settings`, `gtk`, and config file management.

## Available Modules

### Cinnamon (`cinnamon.nix`)
- **Configuration**: dconf-based
- **Theme**: WhiteSur-Dark GTK theme, WhiteSur icons, capitaine-cursors
- **Features**:
  - Auto-hiding panel (macOS-like dock behavior)
  - Window controls on left side
  - Single workspace mode
  - macOS-style window effects
  - Mission Control-like hot corners

### GNOME (`gnome-whitesur.nix`)
- **Configuration**: dconf-based
- **Theme**: WhiteSur-Dark GTK theme, WhiteSur icons, capitaine-cursors
- **Features**:
  - Dash-to-Dock with macOS-like bottom dock
  - Blur effects for transparency
  - Window controls on left side
  - Single workspace mode
  - GNOME Shell extensions for macOS experience

### XFCE (`xfce.nix`)
- **Configuration**: xfconf XML files + GTK settings
- **Theme**: WhiteSur-Dark GTK theme, WhiteSur icons, capitaine-cursors
- **Features**:
  - Window manager theme via XML config
  - Window controls on left side (CmH layout)
  - Single workspace
  - Compositing for transparency

### MATE (`mate.nix`)
- **Configuration**: dconf-based (MATE fork of GNOME 2)
- **Theme**: WhiteSur-Dark GTK theme, WhiteSur icons, capitaine-cursors
- **Features**:
  - Marco window manager configuration
  - Window controls on left side
  - Single workspace
  - Panel transparency support

### LXDE (`lxde.nix`)
- **Configuration**: Openbox XML + GTK settings
- **Theme**: WhiteSur-Dark GTK theme, WhiteSur icons, capitaine-cursors
- **Features**:
  - Openbox window manager configuration
  - Window controls on left (CMN layout)
  - Single workspace
  - GTK theme via .gtkrc-2.0 file

## Usage

### Applying to a User Configuration

Add the appropriate module to your user's Home Manager imports:

```nix
# users/username/hosts/hostname/default.nix
{
  imports = [
    ../../../../modules/home-manager/cinnamon.nix  # For Cinnamon
    # OR
    ../../../../modules/home-manager/gnome-whitesur.nix  # For GNOME
    # OR
    ../../../../modules/home-manager/xfce.nix  # For XFCE
    # OR
    ../../../../modules/home-manager/mate.nix  # For MATE
    # OR
    ../../../../modules/home-manager/lxde.nix  # For LXDE
  ];
}
```

### System-Level Requirements

The system-level desktop environment modules (`modules/nixos/sessions/`) provide:
- Desktop environment packages
- Display manager configuration
- WhiteSur theme packages (via `whitesur-theme.nix`)
- Plank dock (auto-start)
- System-wide font configuration
- XDG portals

The Home Manager modules (this directory) provide:
- User-specific theme settings
- dconf/xfconf configuration
- GTK theme configuration
- Desktop environment behavior settings

## Architecture

### Why Home Manager for Theme Settings?

Previously, theme settings were configured at the system level using `programs.dconf.profiles.user.databases`. This approach had issues:

1. **Doesn't apply declaratively** - Settings weren't automatically applied on rebuild
2. **Wrong abstraction level** - User preferences belong in Home Manager, not system config
3. **Requires manual intervention** - Theme settings only applied on login, not rebuild

The new approach using Home Manager:

1. **Declarative** - Settings apply automatically on `home-manager switch` or system rebuild
2. **Proper separation** - System provides packages, Home Manager configures user preferences
3. **Composable** - Each desktop environment has its own module with appropriate settings

### Integration with System Modules

System modules (`modules/nixos/sessions/`):
- Import `whitesur-theme.nix` for theme packages
- Configure systemd services for setup scripts
- Enable desktop environment and display manager
- Provide compositor and touchpad configuration

Home Manager modules (this directory):
- Apply theme settings via dconf/xfconf
- Configure GTK theme preferences
- Set desktop environment behavior
- Manage config files for window managers

## Rebuilding After Changes

After adding a Home Manager desktop theme module:

```bash
# For NixOS hosts
sudo nixos-rebuild switch --flake .#hostname

# The Home Manager configuration will rebuild automatically
# Theme settings will be applied declaratively
```

## Troubleshooting

### Theme not appearing after rebuild

1. **Check if Home Manager module is imported** in your user configuration
2. **Verify theme packages are installed** at system level (via `whitesur-theme.nix`)
3. **Log out and log back in** - Some desktop environments cache theme settings
4. **Check dconf settings**:
   ```bash
   # For Cinnamon
   gsettings get org.cinnamon.desktop.interface gtk-theme

   # For GNOME
   gsettings get org.gnome.desktop.interface gtk-theme

   # For MATE
   gsettings get org.mate.desktop.interface gtk-theme
   ```

### dconf settings not applying

1. **Ensure `programs.dconf.enable = true`** at system level (in session module)
2. **Check Home Manager syntax** - Use `lib.hm.gvariant.mkInt32` for integers, `lib.hm.gvariant.mkUint32` for unsigned integers
3. **Verify dconf database exists**:
   ```bash
   ls -la ~/.config/dconf/user
   ```

### XFCE/LXDE themes not applying

These desktop environments don't use dconf:
- **XFCE**: Uses xfconf XML files, may require manual configuration via GUI
- **LXDE**: Uses Openbox XML + .gtkrc files, GTK theme applies but Openbox may need GUI configuration

## Future Improvements

- [ ] Create parameterized theme module that works across all DEs
- [ ] Add support for light/dark theme switching
- [ ] Integrate wallpaper management
- [ ] Add keyboard shortcut configuration
- [ ] Support for other themes beyond WhiteSur
