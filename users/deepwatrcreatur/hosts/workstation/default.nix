{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
    ./justfile.nix
    ./nh.nix
    ../../../../modules/home-manager
    ../../../../modules/home-manager/gpg-desktop-linux.nix
    ../../../../modules/home-manager/ghostty
    ../../../../modules/wezterm-config.nix
  ];

  home.username = "deepwatrcreatur";
  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    bitwarden
    ffmpeg
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
}
