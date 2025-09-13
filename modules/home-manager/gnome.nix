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
        "openweather-extension@penguin-teal.github.io"
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

    # OpenWeather extension configuration for Toronto
    "org/gnome/shell/extensions/openweather" = {
      city = "6167865>Toronto, Ontario, Canada>-1";
      unit = "celsius";
      wind-speed-unit = "kph";
      pressure-unit = "kPa";
      show-text-in-panel = true;
      position-in-panel = "center";
      menu-alignment = 75.0;
      translate-condition = true;
      use-symbolic-icons = true;
      show-sunrise-sunset = true;
      show-zero-digit = false;
      center-forecast = false;
      days-forecast = 5;
    };

  };

  # GNOME-specific applications
  home.packages = with pkgs; [
    # Add GNOME-specific user applications here if needed
  ];
}