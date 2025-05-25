{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../modules/home-manager/ghostty
    ../rust.nix
  ];

  home.packages = with pkgs; [
    yt-dlp
    virt-viewer
  ];

}
