{ config, pkgs, lib, ... }:

{
  # GNOME Desktop Environment with COSMIC-like Styling
  # This module configures GNOME to look and behave like COSMIC
  # Works with both GNOME and COSMIC desktop environments
  # System-level setup is in modules/nixos/sessions/gnome.nix

  home.packages = with pkgs; [
    gnomeExtensions.space-bar
    gnomeExtensions.transparent-top-bar
  ];

  dconf.settings = {
    # GNOME/COSMIC shell extension configuration
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "space-bar@luchrioh"
        "transparent-top-bar@kamens.us"
      ];
      # Top bar styling for macOS-like appearance
      "show-applications-button" = false;
      "enable-hot-corners" = false;
    };

    # Note: Panel opacity/transparency settings managed via COSMIC Settings GUI
    # (COSMIC Settings > Panel > Background opacity slider)
    "org.gnome.shell.extensions.cosmic-panel" = {
      background-opacity = 0.5;
    };

    # Dash-to-dock configuration for macOS-like right-aligned dock with enhanced styling
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "LEFT";
      dock-fixed = false;
      intellihide = true;
      autohide = true;
      autohide-in-fullscreen = true;
      show-apps-at-top = true;
      # Enhanced transparency for glossy appearance
      transparency-mode = "FIXED";
      background-opacity = 0.0;
      icon-size-fixed = false;
      max-alpha = 0.95;
      min-alpha = 0.15;
      # Better spacing and sizing for macOS-like feel
      icon-size = 48;
      dash-max-icon-size = 48;
      scroll-action = "cycle-windows";
      shift-click-action = "minimize";
      middle-click-action = "launch";
      # Dock styling
      custom-theme-shrink = true;
      disable-overview-on-startup = false;
    };

    # Space Bar (Numbered Workspaces) configuration
    "org/gnome/shell/extensions/space-bar/behavior" = {
      show-empty-workspaces = false;
    };
    "org/gnome/shell/extensions/space-bar/shortcuts" = {
      enable-activate-workspace-shortcuts = true;
      enable-move-to-workspace-shortcuts = true;
    };

    # Transparent Top Bar configuration
    "org/gnome/shell/extensions/transparent-top-bar" = {
      transparency = 100;
    };

    # COSMIC visual appearance - macOS-like dark theme
    "org/gnome/desktop/interface" = {
      gtk-application-prefer-dark-style = true;
      color-scheme = "prefer-dark";
      # Cursor size (fonts and cursor-theme are set by whitesur module)
      cursor-size = 60;
      gtk-theme = lib.mkForce "WhiteSur-dark";
      icon-theme = lib.mkForce "WhiteSur";
      cursor-theme = lib.mkForce "WhiteSur-cursors";
    };

    # Window decoration - macOS-style button layout (right side, minimize-maximize-close order)
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":close,minimize,maximize";
      focus-mode = "sloppy";
      # Window appearance
      action-middle-click-titlebar = "toggle-maximize";
      action-right-click-titlebar = "menu";
      # Double-click title bar behavior (like macOS)
      action-double-click-titlebar = "maximize";
    };

    # Screen lock and idle configuration
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
    };

    "org/gnome/desktop/lockdown" = {
      disable-lock-screen = true;
    };

    "org/gnome/desktop/session" = {
      idle-delay = 600; # 10 minutes
    };

    # Power management - dims after 2 minutes, no sleep
    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim-timeout = 120;
      sleep-inactive-ac-timeout = 3600; # 1 hour screen off
      sleep-inactive-ac-type = "blank";
    };

    # GTK settings for smooth appearance
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
    };

    # Multi-monitor workspace configuration
    # CRITICAL: Workspaces ONLY on primary (HDMI), secondary (DisplayPort) stays constant
    # This allows DisplayPort to show same content while HDMI switches workspaces
    "org/gnome/mutter" = {
      workspaces-only-on-primary = true; # Workspaces only on primary monitor (HDMI)
      dynamic-workspaces = true; # Dynamic workspaces (create/remove as needed)
    };

    # Wallpaper configuration - set for both monitors
    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/deepwatrcreatur/flakes/unified-nix-configuration/users/deepwatrcreatur/hosts/phoenix/wallpaper.jpg";
      picture-uri-dark = "file:///home/deepwatrcreatur/flakes/unified-nix-configuration/users/deepwatrcreatur/hosts/phoenix/wallpaper.jpg";
      picture-options = "zoom"; # Zoom to fill screen
      primary-color = "#1e1e2e";
      secondary-color = "#1e1e2e";
    };

    # Monitor configuration
    # CRITICAL: With workspaces-only-on-primary=true, the primary monitor gets workspaces
    # To make HDMI switch workspaces while DisplayPort stays constant:
    # 1. Open GNOME Settings > Displays
    # 2. Click on HDMI monitor
    # 3. Enable "Primary Display" toggle
    # Result: HDMI = switches workspaces, DisplayPort = stays constant
  };

  # Home activation reminder for monitor setup
  home.activation.monitorSetupReminder = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD echo ""
    $DRY_RUN_CMD echo "================================================"
    $DRY_RUN_CMD echo " Multi-Monitor Workspace Configuration"
    $DRY_RUN_CMD echo "================================================"
    $DRY_RUN_CMD echo " YES, HDMI needs to be set as PRIMARY for workspaces"
    $DRY_RUN_CMD echo ""
    $DRY_RUN_CMD echo " To configure:"
    $DRY_RUN_CMD echo "   1. Open Settings > Displays"
    $DRY_RUN_CMD echo "   2. Click HDMI monitor"
    $DRY_RUN_CMD echo "   3. Toggle 'Primary Display' ON"
    $DRY_RUN_CMD echo ""
    $DRY_RUN_CMD echo " Result:"
    $DRY_RUN_CMD echo "   • HDMI = switches between workspaces"
    $DRY_RUN_CMD echo "   • DisplayPort = shows same content (constant)"
    $DRY_RUN_CMD echo "================================================"
    $DRY_RUN_CMD echo ""
  '';
}
