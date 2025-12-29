{ config, pkgs, lib, ... }:

{
  # ===========================================
  # Cinnamon Home Manager Configuration
  # ===========================================
  # macOS-like theming and behavior for Cinnamon desktop environment
  # This module provides declarative dconf settings for theme and behavior

  dconf.settings = {
    # ===========================================
    # Desktop Background
    # ===========================================
    "org/cinnamon/desktop/background" = {
      picture-options = "zoom";
      picture-uri = "/run/current-system/sw/share/backgrounds/gnome/nature.jpg";
    };

    # ===========================================
    # Theme Configuration
    # ===========================================
    "org/cinnamon/desktop/interface" = {
      gtk-theme = "WhiteSur-Dark";
      icon-theme = "WhiteSur";
      cursor-theme = "capitaine-cursors";
      cursor-size = 48;
      font-name = "Noto Sans 11";
    };

    # Window manager theme
    "org/cinnamon/desktop/wm/preferences" = {
      theme = "WhiteSur-Dark";
    };

    # Cinnamon shell theme (controls panel appearance)
    "org/cinnamon/theme" = {
      name = "WhiteSur-Dark";
    };

    # ===========================================
    # Panel Behavior (Minimal three-panel layout)
    # ===========================================
    "org/cinnamon" = {
      # Panel positioning - minimal panels that shrink to content
      panels-enabled = [
        "1:0:top"      # Top-left - workspace switcher only
        "2:0:bottom"   # Bottom-right - system tray/icons only
        "3:0:right"    # Right-center - vertical dock with running apps
      ];

      # Panel transparency (no autohide, always visible)
      panel-autohide = false;
      panels-autohide = [
        "1:false"
        "2:false"
        "3:false"
        "4:false"
      ];

      # Panel heights (minimal to fit content)
      panels-height = [
        "1:60"  # Top-left workspace panel - user prefers 60px
        "2:48"  # Bottom-right system tray
        "3:64"  # Right dock - wider for app icons
        "4:40"
      ];

      # Icon sizes for minimal panels
      panel-zone-icon-sizes = lib.hm.gvariant.mkString ''[{"panelId": 1, "left": 24, "center": 0, "right": 0}, {"panelId": 2, "left": 0, "center": 0, "right": 20}, {"panelId": 3, "left": 0, "center": 48, "right": 0}]'';

      # Disable panel barriers for smoother mouse movement
      no-adjacent-panel-barriers = true;

      # Panel applet layout (minimal)
      # Panel 1 (top-left): Workspace switcher only
      # Panel 2 (bottom-right): System tray, notifications, network, sound, clock
      # Panel 3 (right-center): Window list (vertical dock)
      enabled-applets = [
        "panel1:left:0:workspace-switcher@cinnamon.org:5"
        "panel2:right:0:systray@cinnamon.org:0"
        "panel2:right:1:notifications@cinnamon.org:1"
        "panel2:right:2:network@cinnamon.org:2"
        "panel2:right:3:sound150@claudiux:3"
        "panel2:right:4:calendar@cinnamon.org:4"
        "panel3:center:0:window-list@cinnamon.org:7"
      ];

      # Workspace configuration
      number-of-workspaces = lib.hm.gvariant.mkInt32 1;
      workspace-names = [ "Main" ];

      # Alt-Tab behavior (Command-Tab equivalent)
      alttab-switcher-style = "icons";
      alttab-switcher-show = "all-windows";

      # Window effects
      window-effect-close = "fade";
      window-effect-minimize = "scale";
      window-effect-unminimize = "scale";

      # Hot corners - similar to macOS Mission Control
      overview-corner = true;
    };

    # ===========================================
    # Window Manager (Muffin) Settings
    # ===========================================
    "org/cinnamon/muffin" = {
      # Window controls on left side (macOS-style)
      button-layout = "close,minimize,maximize:";

      # Focus behavior
      focus-mode = "click";
      auto-raise = false;
      raise-on-click = true;

      # Disable edge tiling (not macOS-like)
      edge-tiling = false;
      dynamic-workspaces = false;
      workspace-cycle = false;
    };

    # ===========================================
    # Keyboard Shortcuts
    # ===========================================
    "org/cinnamon/desktop/keybindings" = {
      # These would be set by the keybinds-config.sh script
      # Keeping them here for reference but the script handles the details
    };
  };

  # ===========================================
  # Cinnamon-specific packages
  # ===========================================
  home.packages = with pkgs; [
    # Additional Cinnamon tools if needed
  ];

  # ===========================================
  # Cinnamon Panel Transparency (Note)
  # ===========================================
  # Unfortunately, Cinnamon panel transparency settings are stored in a complex
  # format that changes based on panel configuration and cannot be easily
  # managed declaratively. The transparency must be set through the GUI:
  # Right-click panel → Panel Settings → Panel → Enable custom transparency
  #
  # Alternative: Use a transparent theme or compositor (picom) for transparency

  # ===========================================
  # Plank Dock Configuration (Declarative)
  # ===========================================
  # Plank configuration for macOS-like dock at bottom

  home.file.".config/plank/dock1/settings".text = ''
    [PlankDockPreferences]
    DockItems=firefox.dockitem;;google-chrome.dockitem;;ghostty.dockitem;;wezterm.dockitem;;
    HideMode=intelligent
    Theme=Transparent
    IconSize=48
    Position=bottom
    Alignment=center
    ItemsAlignment=center
    Offset=0
    PressureReveal=false
    ShowDockItem=false
    LockItems=false
    UnhideDelay=0
    AutoPinning=true
    ZoomEnabled=true
    ZoomPercent=150
  '';

  # ===========================================
  # Plank Service (Disabled)
  # ===========================================
  # NOTE: Plank is disabled - using Cinnamon panel as vertical dock instead
  # The right panel (panel2) acts as the application dock
  # Uncomment below if you want to use Plank instead

  # systemd.user.services.plank = {
  #   Unit = {
  #     Description = "Plank macOS-like dock";
  #     After = [ "graphical-session.target" ];
  #     PartOf = [ "graphical-session.target" ];
  #   };
  #
  #   Service = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.plank}/bin/plank";
  #     Restart = "on-failure";
  #     RestartSec = 3;
  #   };
  #
  #   Install = {
  #     WantedBy = [ "graphical-session.target" ];
  #   };
  # };
}
