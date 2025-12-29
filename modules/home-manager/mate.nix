{ config, pkgs, lib, ... }:

{
  # ===========================================
  # MATE Home Manager Configuration
  # ===========================================
  # macOS-like theming for MATE desktop environment
  # MATE uses dconf for settings (fork of GNOME 2)

  dconf.settings = {
    # ===========================================
    # Theme Configuration
    # ===========================================
    "org/mate/desktop/interface" = {
      gtk-theme = "WhiteSur-Dark";
      icon-theme = "WhiteSur";
      font-name = "Noto Sans 11";
    };

    # ===========================================
    # Window Manager (Marco) Settings
    # ===========================================
    "org/mate/marco/general" = {
      # Window controls on left side (macOS-style)
      button-layout = "close,minimize,maximize:";

      # Focus behavior
      focus-mode = "click";
      auto-raise = false;
      raise-on-click = true;

      # Window manager theme
      theme = "WhiteSur-Dark";

      # Compositing for transparency
      compositing-manager = true;
    };

    # ===========================================
    # Panel Configuration
    # ===========================================
    "org/mate/panel/general" = {
      # Panel transparency
      enable-slab = false;
      tooltips-enabled = true;
    };

    # ===========================================
    # Desktop Background
    # ===========================================
    "org/mate/desktop/background" = {
      picture-filename = "/run/current-system/sw/share/backgrounds/gnome/nature.jpg";
      picture-options = "zoom";
    };

    # ===========================================
    # Workspace Configuration
    # ===========================================
    "org/mate/marco/workspace-names" = {
      name-1 = "Main";
    };

    "org/mate/marco/general" = {
      num-workspaces = 1;
    };

    # ===========================================
    # Session Configuration
    # ===========================================
    "org/mate/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 0;  # Disable auto-lock
    };

    # ===========================================
    # Cursor Theme
    # ===========================================
    "org/mate/desktop/peripherals/mouse" = {
      cursor-theme = "capitaine-cursors";
      cursor-size = 24;
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
  # MATE-specific packages
  # ===========================================
  home.packages = with pkgs; [
    # MATE tools for macOS-like experience
    mate.mate-panel
    mate.mate-applets
  ];
}
