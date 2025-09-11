{ config, pkgs, ... }:

{
  # GNOME Home Manager configuration
  dconf.settings = {
    "org/gnome/shell" = {
      # Enable extensions
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "gsconnect@andyholmes.github.io" 
        "clipboard-indicator@tudmotu.com"
        "pop-shell@system76.com"
      ];
    };

    # Dash to Dock configuration
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      dock-fixed = false;
      intellihide = true;
      show-apps-at-top = true;
    };

    # Pop Shell (tiling) configuration
    "org/gnome/shell/extensions/pop-shell" = {
      tile-by-default = true;
      gap-inner = 4;
      gap-outer = 4;
      smart-gaps = true;
    };

    # GNOME desktop preferences
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      icon-theme = "BeautyLine";
    };

    # Window management
    "org/gnome/desktop/wm/preferences" = {
      focus-mode = "sloppy";
      resize-with-right-button = true;
    };
  };

  # GNOME-specific applications
  home.packages = with pkgs; [
    # Add GNOME-specific user applications here if needed
  ];
}