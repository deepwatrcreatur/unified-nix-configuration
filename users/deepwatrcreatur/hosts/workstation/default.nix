{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
    ./nh.nix
    ../../../../modules/home-manager
    ../../../../modules/home-manager/gpg-desktop-linux.nix
    ../../../../modules/home-manager/ghostty
    ../../../../modules/home-manager/linuxbrew.nix
    #../../../../modules/home-manager/gnome.nix
    ../../../../modules/home-manager/zed.nix
    ../../../../modules/home-manager/zen.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    bitwarden-desktop
    ffmpeg
    gitkraken
    deskflow
    mailspring
    megacmd
    obsidian
    obsidian-export
    virt-viewer
  ];

  programs.firefox = {
    enable = true;
  };

  programs.google-chrome = {
    enable = true;
  };

  home.file.".justfile".source = ./justfile; # Directly link the justfile

  home.file.".config/deskflow/deskflow.conf".text = ''
    clipboardSharing = true
  '';

  # Deskflow server service
  systemd.user.services.deskflow = {
    Unit = {
      Description = "Deskflow Server";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.deskflow}/bin/deskflow server --config ${config.home.homeDirectory}/.config/deskflow/deskflow.conf
      '';
      Restart = "on-failure";
      RestartSec = "5";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  home.stateVersion = "24.11";
}
