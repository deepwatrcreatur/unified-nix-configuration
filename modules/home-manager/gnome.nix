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
        "transparent-window-moving@noobsai.github.com"
        "blur-my-shell@aunetx"
        "weatheroclock@CleoMenezesJr.github.io"
        "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
        "places-menu@gnome-shell-extensions.gcampax.github.com"
        "apps-menu@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
        "status-icons@gnome-shell-extensions.gcampax.github.com"
      ];
    };

    # Dash to Dock configuration
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "RIGHT";
      dock-fixed = true;
      intellihide = false;
      show-apps-at-top = true;
      transparency-mode = "DYNAMIC";
      background-opacity = 0.3;
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
      gtk-theme = "Adwaita-dark";
      enable-animations = true;
    };

    # Window management
    "org/gnome/desktop/wm/preferences" = {
      focus-mode = "sloppy";
      resize-with-right-button = true;
      num-workspaces = 4;
    };

    # Dynamic workspaces
    "org/gnome/mutter" = {
      dynamic-workspaces = true;
      workspaces-only-on-primary = true;
    };

    # Screen lock and session settings
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
      idle-activation-enabled = false;
    };

    "org/gnome/desktop/session" = {
      idle-delay = "uint32 0";  # Disable idle timeout
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };

    # Blur My Shell extension configuration for transparency
    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      blur = true;
      brightness = 0.8;
      sigma = 15;
      static-blur = true;
      unblur-in-overview = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = 0.7;
      sigma = 15;
      static-blur = true;
      unblur-in-overview = false;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur = false;  # Don't blur application windows by default
    };


  };

  # GNOME-specific applications
  home.packages = with pkgs; [
    # Add GNOME-specific user applications here if needed
  ];

  # Enable GNOME Keyring for password management
  services.gnome-keyring = {
    enable = true;
    # Disable the SSH component to avoid conflicts with other agents
    components = ["pkcs11" "secrets"];
  };
}