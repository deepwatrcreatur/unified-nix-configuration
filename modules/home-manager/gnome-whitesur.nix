{ config, pkgs, lib, ... }:

{
  # ===========================================
  # GNOME Home Manager Configuration - WhiteSur Theme
  # ===========================================
  # macOS-like theming for GNOME desktop environment
  # This provides WhiteSur theme variant, while gnome.nix provides Garuda theme

  dconf.settings = {
    # ===========================================
    # Theme Configuration
    # ===========================================
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "WhiteSur-Dark";
      icon-theme = "WhiteSur";
      cursor-theme = "capitaine-cursors";
      cursor-size = 24;
      font-name = "Noto Sans 11";
      enable-animations = true;
    };

    # ===========================================
    # Window Manager Settings
    # ===========================================
    "org/gnome/desktop/wm/preferences" = {
      # Window controls on left (macOS-style)
      button-layout = "close,minimize,maximize:";

      # Focus behavior
      focus-mode = "click";
      resize-with-right-button = true;

      # Single workspace (macOS-like)
      num-workspaces = 1;

      # Window manager theme
      theme = "WhiteSur-Dark";
    };

    # ===========================================
    # Workspace Configuration
    # ===========================================
    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      workspaces-only-on-primary = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      workspace-names = [ "Main" ];
    };

    # ===========================================
    # GNOME Shell Extensions
    # ===========================================
    "org/gnome/shell" = {
      # Enable extensions for macOS-like experience
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "blur-my-shell@aunetx"
        "clipboard-indicator@tudmotu.com"
      ];
    };

    # ===========================================
    # Dash to Dock Configuration (macOS-like floating dock)
    # ===========================================
    "org/gnome/shell/extensions/dash-to-dock" = {
      # Position and size
      dock-position = "RIGHT";  # Vertical dock on right edge
      dock-fixed = false;  # Floating dock (not spanning full edge)
      extend-height = false;  # Don't extend to full height
      dock-alignment = "CENTER";  # Center the dock vertically

      # Auto-hide behavior
      autohide = false;  # Always visible with transparency
      intellihide = false;  # Don't hide when windows overlap

      # Transparency
      transparency-mode = "DYNAMIC";
      background-opacity = 0.3;
      customize-alphas = true;
      min-alpha = 0.2;
      max-alpha = 0.8;

      # Icon configuration
      icon-size-fixed = true;
      dash-max-icon-size = 48;
      show-apps-at-top = false;

      # Behavior
      click-action = "minimize-or-previews";  # macOS-like click behavior
      scroll-action = "cycle-windows";

      # Appearance
      apply-custom-theme = true;
      custom-theme-shrink = false;
      running-indicator-style = "DOTS";  # Show dots for running apps (macOS style)
    };

    # ===========================================
    # Blur My Shell Extension (transparency)
    # ===========================================
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
      blur = false;
    };

    # ===========================================
    # Desktop Background
    # ===========================================
    "org/gnome/desktop/background" = {
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/nature.jpg";
      picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/nature.jpg";
      picture-options = "zoom";
    };

    # ===========================================
    # Screen Lock and Session Settings
    # ===========================================
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
      idle-activation-enabled = false;
    };

    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 0;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };
  };

  # ===========================================
  # GTK Theme Configuration (fallback)
  # ===========================================
  gtk = {
    enable = true;

    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };

    iconTheme = {
      name = "WhiteSur";
      package = pkgs.whitesur-icon-theme;
    };

    cursorTheme = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
    };

    font = {
      name = "Noto Sans";
      size = 11;
    };
  };

  # ===========================================
  # GNOME-specific packages
  # ===========================================
  home.packages = with pkgs; [
    gnome-tweaks
  ];

  # ===========================================
  # GNOME Keyring
  # ===========================================
  services.gnome-keyring = {
    enable = true;
    components = [
      "pkcs11"
      "secrets"
    ];
  };
}
