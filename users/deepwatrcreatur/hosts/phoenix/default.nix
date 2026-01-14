{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../../default.nix
    ./nh.nix
    ./distrobox.nix

    ../../../../modules/home-manager
    ../../../../modules/home-manager/ghostty
    ../../../../modules/home-manager/gpg-agent-cross-de.nix
    ../../../../modules/home-manager/zed.nix
    ../../../../modules/home-manager/hyprland/default.nix # Hyprland configuration
    #../../../../modules/home-manager/cosmic-settings.nix # Replaced with Hyprland
    inputs.zellij-vivid-rounded.homeManagerModules.default
    inputs.nix-whitesur-config.homeManagerModules.default
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  # WhiteSur theming for COSMIC
  whitesur = {
    enable = true;
    gtk.enable = true;
  };

  programs.zellij-vivid-rounded = {
    enable = true;
  };

  programs.distrobox.fedora.enable = true;

  home.packages = with pkgs; [
    bitwarden-desktop
    ffmpeg
    gitkraken
    deskflow
    megacmd
    obsidian
    obsidian-export
    rustdesk
    virt-viewer
    xorg.xhost # X11 host access control for DeskFlow
  ];

  programs.firefox = {
    enable = true;
  };

  programs.google-chrome = {
    enable = true;
  };

  home.file.".config/deskflow/deskflow.conf".text = ''
    clipboardSharing = true
  '';

  # X11 display setup for DeskFlow
  systemd.user.services.xhost-deskflow = {
    Unit = {
      Description = "X11 host access for DeskFlow";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.xorg.xhost}/bin/xhost +local:";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Deskflow server service (disabled in favor of RustDesk)
  # Start manually with: systemctl --user start deskflow
  systemd.user.services.deskflow = {
    Unit = {
      Description = "Deskflow Server";
      After = [
        "graphical-session.target"
        "xhost-deskflow.service"
      ];
      Wants = [
        "graphical-session.target"
        "xhost-deskflow.service"
      ];
    };
    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.deskflow}/bin/deskflow server --config ${config.home.homeDirectory}/.config/deskflow/deskflow.conf
      '';
      Restart = "on-failure";
      RestartSec = "5";
      Environment = [
        "DISPLAY=:0"
        "XAUTHORITY=${config.xdg.cacheHome}/.Xauthority"
      ];
    };
    Install = {
      # Disabled: WantedBy = [ "graphical-session.target" ];
    };
  };

  home.stateVersion = "24.11";
}
