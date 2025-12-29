# Desktop Theming Flake - Usage Guide

## As a Standalone Flake

This theming system can be used as a standalone flake in your own NixOS or Home Manager configuration.

### Adding as a Flake Input

```nix
# Your flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Add desktop theming flake
    desktop-theming = {
      url = "github:yourusername/desktop-theming";  # Replace with actual URL
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, desktop-theming, ... }: {
    # Your outputs here
  };
}
```

### NixOS Configuration

```nix
# hosts/yourhost/configuration.nix
{ config, pkgs, inputs, ... }:

{
  imports = [
    # Import theming modules
    inputs.desktop-theming.nixosModules.default
    inputs.desktop-theming.nixosModules.packages
  ];

  # Configure theming
  desktopTheming = {
    enable = true;
    theme = "whitesur";      # whitesur | arc | adwaita
    variant = "dark";        # dark | light

    cursor.size = 48;

    dock = {
      position = "right";
      alignment = "center";
      iconSize = 48;
      transparency = 0.3;
    };

    panel = {
      height = 60;
      transparency = 0.3;
    };
  };
}
```

### Home Manager Configuration

For **NixOS with Home Manager as a module**:

```nix
# hosts/yourhost/configuration.nix
{
  home-manager.users.youruser = { config, ... }: {
    imports = [
      inputs.desktop-theming.homeManagerModules.default
      inputs.desktop-theming.homeManagerModules.cinnamon  # or .gnome
    ];

    # desktopTheming options inherited from system config
  };
}
```

For **Standalone Home Manager**:

```nix
# home.nix
{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.desktop-theming.homeManagerModules.default
    inputs.desktop-theming.homeManagerModules.gnome  # or .cinnamon
  ];

  # Configure theming directly
  desktopTheming = {
    enable = true;
    theme = "whitesur";
    variant = "dark";
    cursor.size = 48;

    dock = {
      position = "right";
      alignment = "center";
      iconSize = 48;
      transparency = 0.3;
    };

    # GNOME-specific settings
    gnome.extensions = [
      "dash-to-dock@micxgx.gmail.com"
      "blur-my-shell@aunetx"
    ];
  };
}
```

## Desktop Environment Examples

### Cinnamon Desktop

```nix
{
  imports = [
    inputs.desktop-theming.nixosModules.default
    inputs.desktop-theming.nixosModules.packages
  ];

  # System configuration
  desktopTheming = {
    enable = true;
    theme = "whitesur";
    variant = "dark";

    cinnamon = {
      panels = [ "1:0:top" "2:0:bottom" "3:0:right" ];
      panelHeights = [ "1:60" "2:48" "3:64" ];
    };
  };

  # Home Manager
  home-manager.users.youruser = {
    imports = [
      inputs.desktop-theming.homeManagerModules.default
      inputs.desktop-theming.homeManagerModules.cinnamon
    ];
  };
}
```

### GNOME Desktop

```nix
{
  imports = [
    inputs.desktop-theming.nixosModules.default
    inputs.desktop-theming.nixosModules.packages
  ];

  # System configuration
  desktopTheming = {
    enable = true;
    theme = "whitesur";
    variant = "dark";

    dock = {
      position = "right";
      alignment = "center";
      iconSize = 48;
      transparency = 0.3;
    };

    gnome.extensions = [
      "dash-to-dock@micxgx.gmail.com"
      "blur-my-shell@aunetx"
      "clipboard-indicator@tudmotu.com"
    ];
  };

  # Home Manager
  home-manager.users.youruser = {
    imports = [
      inputs.desktop-theming.homeManagerModules.default
      inputs.desktop-theming.homeManagerModules.gnome
    ];
  };
}
```

## Available Options

### Core Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `desktopTheming.enable` | bool | false | Enable desktop theming |
| `desktopTheming.theme` | enum | "whitesur" | Theme name (whitesur, arc, adwaita, custom) |
| `desktopTheming.variant` | enum | "dark" | Theme variant (dark, light) |
| `desktopTheming.cursor.theme` | string | "capitaine-cursors" | Cursor theme name |
| `desktopTheming.cursor.size` | int | 48 | Cursor size in pixels |
| `desktopTheming.icons.theme` | string | "WhiteSur" | Icon theme name |
| `desktopTheming.fonts.sans` | string | "Noto Sans" | Sans-serif font |
| `desktopTheming.fonts.mono` | string | "Fira Code" | Monospace font |
| `desktopTheming.fonts.size` | int | 11 | Default font size |

### Dock Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `desktopTheming.dock.position` | enum | "right" | Dock position (left, right, top, bottom) |
| `desktopTheming.dock.alignment` | enum | "center" | Dock alignment (start, center, end) |
| `desktopTheming.dock.iconSize` | int | 48 | Dock icon size in pixels |
| `desktopTheming.dock.transparency` | float | 0.3 | Dock transparency (0.0-1.0) |

### Panel Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `desktopTheming.panel.height` | int | 48 | Panel height in pixels |
| `desktopTheming.panel.transparency` | float | 0.3 | Panel transparency (0.0-1.0) |

### Desktop-Specific Options

#### Cinnamon

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `desktopTheming.cinnamon.panels` | list of strings | ["1:0:top" "2:0:bottom" "3:0:right"] | Panel configuration |
| `desktopTheming.cinnamon.panelHeights` | list of strings | ["1:60" "2:48" "3:64" "4:40"] | Panel heights |
| `desktopTheming.cinnamon.applets` | list of strings | [] | Custom applet configuration |

#### GNOME

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `desktopTheming.gnome.extensions` | list of strings | ["dash-to-dock@micxgx.gmail.com" ...] | Enabled GNOME extensions |

## Module Outputs

### nixosModules

- `default` - Core options module (defines `desktopTheming.*` options)
- `packages` - Package installer (installs theme packages system-wide)

### homeManagerModules

- `default` - GTK/Qt theming for Home Manager
- `cinnamon` - Cinnamon desktop adapter
- `gnome` - GNOME desktop adapter

## Development

To work on the flake itself:

```bash
# Enter development shell
nix develop

# Format Nix files
nixpkgs-fmt .

# Check for issues
statix check .
```

## Contributing

Contributions are welcome! Please:

1. Add new desktop environments as adapters in `desktops/`
2. Follow existing patterns for option naming
3. Use `mkDefault` for settings that might conflict
4. Update documentation in README.md and this file
5. Test changes with `nix flake check`

## License

Same as parent project (MIT/BSD/etc.)
