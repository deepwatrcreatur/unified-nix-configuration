# Modular Desktop Theming System

A reusable, composable system for declarative desktop environment theming with macOS-like appearance.

## Architecture

This theming system is designed as **reusable components** that can be:
- Used across multiple desktop environments (GNOME, Cinnamon, XFCE, etc.)
- Extracted to a separate flake for use in other projects
- Configured once, applied everywhere

### Module Structure

```
modules/shared/desktop-theming/
├── default.nix          # Core options (theme, colors, sizes, etc.)
├── packages.nix         # System-level theme packages
├── home.nix             # Home Manager GTK/Qt theming
└── desktops/
    ├── cinnamon.nix     # Cinnamon-specific adapter
    ├── gnome.nix        # GNOME-specific adapter
    ├── xfce.nix         # XFCE-specific adapter (future)
    └── mate.nix         # MATE-specific adapter (future)
```

### Design Principles

1. **Single Source of Truth**: Configure theme options once in `desktopTheming.*`
2. **Desktop Adapters**: Each DE reads shared options and applies them appropriately
3. **Separation of Concerns**:
   - `default.nix` - Options only
   - `packages.nix` - System packages
   - `home.nix` - User-level theming (GTK/Qt)
   - `desktops/*.nix` - DE-specific dconf/config

## Usage

### Basic Setup (System-Level)

```nix
# In your NixOS configuration
{
  imports = [
    ./modules/shared/desktop-theming
    ./modules/shared/desktop-theming/packages.nix
  ];

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

    panel.height = 60;
  };
}
```

### Home Manager Configuration

```nix
# In your Home Manager config
{
  imports = [
    ./modules/shared/desktop-theming/home.nix
    ./modules/shared/desktop-theming/desktops/cinnamon.nix  # Or gnome.nix
  ];

  # desktopTheming options are inherited from system config on NixOS
  # Or configure directly for standalone Home Manager:
  desktopTheming = {
    enable = true;
    theme = "whitesur";
    variant = "dark";
    # ... same options as above
  };
}
```

### Desktop-Specific Configuration

#### Cinnamon

```nix
{
  imports = [
    ./modules/shared/desktop-theming/desktops/cinnamon.nix
  ];

  desktopTheming = {
    enable = true;
    theme = "whitesur";

    cinnamon = {
      panels = [ "1:0:top" "2:0:bottom" "3:0:right" ];
      panelHeights = [ "1:60" "2:48" "3:64" ];
      # applets = [ ... ];  # Optional custom applet config
    };
  };
}
```

#### GNOME

```nix
{
  imports = [
    ./modules/shared/desktop-theming/desktops/gnome.nix
  ];

  desktopTheming = {
    enable = true;
    theme = "whitesur";

    dock = {
      position = "right";
      alignment = "center";
    };

    gnome.extensions = [
      "dash-to-dock@micxgx.gmail.com"
      "blur-my-shell@aunetx"
    ];
  };
}
```

## Available Options

### Core Options

```nix
desktopTheming = {
  enable = true;                    # Enable theming system
  theme = "whitesur";               # whitesur | arc | adwaita | custom
  variant = "dark";                 # dark | light

  cursor = {
    theme = "capitaine-cursors";   # Cursor theme name
    size = 48;                      # Cursor size in pixels
  };

  icons.theme = "WhiteSur";         # Icon theme name

  fonts = {
    sans = "Noto Sans";             # Sans-serif font
    mono = "Fira Code";             # Monospace font
    size = 11;                      # Default font size
  };

  dock = {
    position = "right";             # left | right | top | bottom
    alignment = "center";           # start | center | end
    iconSize = 48;                  # Icon size in pixels
    transparency = 0.3;             # 0.0-1.0 (lower = more transparent)
  };

  panel = {
    height = 48;                    # Panel height in pixels
    transparency = 0.3;             # 0.0-1.0
  };
};
```

### Desktop-Specific Options

#### Cinnamon Options

```nix
desktopTheming.cinnamon = {
  panels = [ "1:0:top" "2:0:bottom" "3:0:right" ];
  panelHeights = [ "1:60" "2:48" "3:64" "4:40" ];
  applets = [ /* custom applet configuration */ ];
};
```

#### GNOME Options

```nix
desktopTheming.gnome = {
  extensions = [
    "dash-to-dock@micxgx.gmail.com"
    "blur-my-shell@aunetx"
    "clipboard-indicator@tudmotu.com"
  ];
};
```

## Benefits of This Architecture

### 1. **Reusable**
```nix
# Same config works across DEs:
desktopTheming.theme = "whitesur";  # Works in GNOME, Cinnamon, XFCE, etc.
```

### 2. **Composable**
```nix
# Mix and match modules:
imports = [
  desktop-theming/home.nix        # GTK theming
  desktop-theming/desktops/gnome.nix  # GNOME specifics
];
```

### 3. **Maintainable**
- Change theme once: `desktopTheming.theme = "arc";`
- Automatically updates GTK, icons, cursor, DE-specific settings

### 4. **Extractable**
Easy to move to a separate flake:
```nix
# flake.nix
{
  outputs = { nixpkgs, ... }: {
    nixosModules.desktop-theming = import ./default.nix;
    homeManagerModules.desktop-theming = import ./home.nix;
  };
}
```

## Migration from Old System

### Before (Monolithic)
```nix
# modules/home-manager/cinnamon.nix - 200 lines, hardcoded theme
dconf.settings."org/cinnamon/desktop/interface" = {
  gtk-theme = "WhiteSur-Dark";  # Hardcoded!
  icon-theme = "WhiteSur";
  cursor-theme = "capitaine-cursors";
  # ... 150 more lines
};
```

### After (Modular)
```nix
# Just configure options
desktopTheming = {
  theme = "whitesur";  # Can change to "arc" easily
  variant = "dark";
};

# Import the adapter
imports = [ desktop-theming/desktops/cinnamon.nix ];
```

## Future: Separate Flake

This system is designed to be extracted to a standalone flake:

```nix
# Your future flake.nix
{
  description = "Reusable desktop theming for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }: {
    nixosModules = {
      default = import ./default.nix;
      packages = import ./packages.nix;
    };

    homeManagerModules = {
      default = import ./home.nix;
      cinnamon = import ./desktops/cinnamon.nix;
      gnome = import ./desktops/gnome.nix;
    };
  };
}
```

Others would use it like:
```nix
inputs.desktop-theming.url = "github:yourusername/desktop-theming";

imports = [
  inputs.desktop-theming.nixosModules.default
  inputs.desktop-theming.nixosModules.packages
  inputs.desktop-theming.homeManagerModules.cinnamon
];
```

## Examples

See the `examples/` directory for:
- Full NixOS + Home Manager setup
- Standalone Home Manager usage
- Multi-desktop configuration

## Contributing

When adding a new desktop environment:

1. Create `desktops/yourde.nix`
2. Read from `cfg = config.desktopTheming`
3. Apply settings to your DE's config format
4. Add DE-specific options under `desktopTheming.yourde.*`
5. Update this README

## License

Same as parent configuration (MIT/BSD/etc.)
