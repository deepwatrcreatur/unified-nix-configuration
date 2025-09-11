{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
    ./justfile.nix
    ./nh.nix
    ../../../../modules/home-manager
    ../../../../modules/home-manager/gpg-desktop-linux.nix
    ../../../../modules/home-manager/ghostty
    ../../../../modules/home-manager/linuxbrew.nix
  ];

  home.username = "deepwatrcreatur";
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
}
