{ config, pkgs, lib, ... }:

{
  imports = [
    ./whitesur-theme.nix
  ];

  # ===========================================
  # Base Configuration
  # ===========================================

  # Enable X11 windowing system.
  services.xserver.enable = true;

  # Enable Cinnamon desktop environment.
  services.xserver.desktopManager.cinnamon.enable = true;

  # Configure autorepeat for Proxmox guest to prevent stuck keypresses
  services.xserver.autoRepeatDelay = 300;
  services.xserver.autoRepeatInterval = 40;

  # Enable LightDM display manager for Cinnamon
  services.xserver.displayManager.lightdm.enable = true;

  # Enable autologin
  services.displayManager.autoLogin = {
    enable = true;
    user = "deepwatrcreatur";
  };

  # ===========================================
  # Cinnamon-Specific Packages
  # ===========================================

  environment.systemPackages = with pkgs; [
    # Application launcher - Ulauncher (similar to Spotlight/Alfred)
    # Launch with Ctrl+Space (configurable in Ulauncher preferences)
    ulauncher
    
    # Configuration tools
    dconf  # Settings backend
  ];

  # ===========================================
  # Cinnamon-Specific XDG Portals
  # ===========================================

  xdg.portal = {
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # ===========================================
  # Ulauncher Configuration
  # ===========================================

  # Enable Ulauncher to start on login
  systemd.user.services.ulauncher = lib.mkIf config.services.xserver.enable {
    description = "Ulauncher application launcher";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.ulauncher}/bin/ulauncher --hide-window";
      Restart = "on-failure";
    };
  };

  # Auto-start Cinnamon desktop configuration
  systemd.user.services.cinnamon-config = lib.mkIf config.services.xserver.enable {
    description = "Configure Cinnamon for macOS-like behavior";
    wantedBy = [ "graphical-session.target" ];
    after = [ "ulauncher.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${./cinnamon/cinnamon-config.sh}";
      RemainAfterExit = true;
    };
  };

  # Auto-start keyboard shortcuts configuration
  systemd.user.services.keybinds-config = lib.mkIf config.services.xserver.enable {
    description = "Configure macOS-like keyboard shortcuts";
    wantedBy = [ "graphical-session.target" ];
    after = [ "cinnamon-config.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${./cinnamon/keybinds-config.sh}";
      RemainAfterExit = true;
    };
  };

  # ===========================================
  # Compositor Configuration
  # ===========================================
  # NOTE: Picom is disabled for Cinnamon because it has its own compositor (Muffin)
  # Running both causes conflicts.

  services.picom.enable = false;  # Disabled - conflicts with Cinnamon's Muffin

  # ===========================================
  # Touchpad Configuration
  # ===========================================

  # ===========================================
  # Cinnamon-Specific Theme Configuration
  # ===========================================
  # NOTE: Theme and appearance settings are now configured via Home Manager
  # See: modules/home-manager/cinnamon.nix
  # This provides declarative dconf settings that properly apply on rebuild

  # System message on first login
  system.activationScripts.cinnamonMacosSetup = lib.mkAfter ''
    mkdir -p /etc/cinnamon-macos-config
    echo "macOS-like Cinnamon configuration initialized" > /etc/cinnamon-macos-config/status
    echo "Theme settings configured via Home Manager (modules/home-manager/cinnamon.nix)" >> /etc/cinnamon-macos-config/status
  '';
}
