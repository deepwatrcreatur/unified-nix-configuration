{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../default.nix
    ./justfile.nix
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
    megacmd
    thunderbird-bin
    virt-viewer
  ];

  programs.firefox = {
    enable = true;
  };

  programs.google-chrome = {
    enable = true;
  };
}
