{
  config,
  pkgs,
  lib,
  ...
}:

{
  # GNOME Desktop Environment with COSMIC-like styling and behavior.
  # This module is intended for GNOME sessions that emulate the COSMIC look,
  # not for the native COSMIC desktop session itself.

  home.packages = with pkgs; [
    gnomeExtensions.space-bar
    gnomeExtensions.transparent-top-bar
  ];

  dconf.settings = {
    # GNOME shell extensions for the COSMIC-like shell layout.
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
        "space-bar@luchrioh"
        "transparent-top-bar@kamens.us"
      ];
      "show-applications-button" = false;
      "enable-hot-corners" = false;
    };

    "org.gnome.shell.extensions.cosmic-panel" = {
      background-opacity = 0.5;
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "LEFT";
      dock-fixed = false;
      intellihide = true;
      autohide = true;
      autohide-in-fullscreen = true;
      show-apps-at-top = true;
      transparency-mode = "FIXED";
      background-opacity = 0.0;
      icon-size-fixed = false;
      max-alpha = 0.95;
      min-alpha = 0.15;
      icon-size = 48;
      dash-max-icon-size = 48;
      scroll-action = "cycle-windows";
      shift-click-action = "minimize";
      middle-click-action = "launch";
      custom-theme-shrink = true;
      disable-overview-on-startup = false;
    };

    "org/gnome/shell/extensions/space-bar/behavior" = {
      show-empty-workspaces = false;
    };
    "org/gnome/shell/extensions/space-bar/shortcuts" = {
      enable-activate-workspace-shortcuts = true;
      enable-move-to-workspace-shortcuts = true;
    };

    "org/gnome/shell/extensions/transparent-top-bar" = {
      transparency = 100;
    };

    "org/gnome/desktop/interface" = {
      gtk-application-prefer-dark-style = true;
      color-scheme = "prefer-dark";
      cursor-size = 60;
      gtk-theme = lib.mkForce "WhiteSur-dark";
      icon-theme = lib.mkForce "WhiteSur";
      cursor-theme = lib.mkForce "WhiteSur-cursors";
    };

    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":close,minimize,maximize";
      focus-mode = "sloppy";
      action-middle-click-titlebar = "toggle-maximize";
      action-right-click-titlebar = "menu";
      action-double-click-titlebar = "maximize";
    };

    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
      lock-delay = 0;
      idle-activation-enabled = false;
      ubuntu-lock-on-suspend = false;
    };

    "org/gnome/desktop/lockdown" = {
      disable-lock-screen = true;
    };

    "org/gnome/desktop/session" = {
      idle-delay = 0;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim = false;
      idle-dim-timeout = 0;
      sleep-inactive-ac-timeout = 0;
      sleep-inactive-battery-timeout = 0;
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
    };

    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
    };

    # GNOME supports workspaces only on the primary display, which is the
    # behavior wanted on workstation: HDMI switches, DisplayPort stays fixed.
    "org/gnome/mutter" = {
      workspaces-only-on-primary = true;
      dynamic-workspaces = true;
    };

    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/deepwatrcreatur/flakes/unified-nix-configuration/users/deepwatrcreatur/hosts/phoenix/wallpaper.jpg";
      picture-uri-dark = "file:///home/deepwatrcreatur/flakes/unified-nix-configuration/users/deepwatrcreatur/hosts/phoenix/wallpaper.jpg";
      picture-options = "zoom";
      primary-color = "#1e1e2e";
      secondary-color = "#1e1e2e";
    };
  };

  # Keep COSMIC idle settings disabled in case native COSMIC tools are present.
  xdg.configFile = {
    "cosmic/com.system76.CosmicIdle/v1/screen_off_time".text = "None";
    "cosmic/com.system76.CosmicIdle/v1/suspend_on_ac_time".text = "None";
    "cosmic/com.system76.CosmicIdle/v1/suspend_on_battery_time".text = "None";
  };

  home.activation.monitorSetupReminder = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
