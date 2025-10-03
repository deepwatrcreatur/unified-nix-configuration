{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
    ./nh.nix
    ../../../../modules/home-manager
    ../../../../modules/home-manager/gnupg-desktop-linux.nix
    ../../../../modules/home-manager/ghostty
    ../../../../modules/home-manager/linuxbrew.nix
    ../../../../modules/home-manager/gnome.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    bitwarden
    ffmpeg
    gitkraken
    input-leap
    mailspring
    megacmd
    virt-viewer
  ];

  programs.firefox = {
    enable = true;
  };

  programs.google-chrome = {
    enable = true;
  };

  home.file.".justfile".source = ./justfile; # Directly link the justfile

  # Input Leap client service
  systemd.user.services.input-leap-client = {
    Unit = {
      Description = "Input Leap Client";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.input-leap}/bin/input-leapc --no-daemon --name workstation 10.10.11.150";
      Restart = "on-failure";
      RestartSec = "5";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  home.stateVersion = "24.11";
}
