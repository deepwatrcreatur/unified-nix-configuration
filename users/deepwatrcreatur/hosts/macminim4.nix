{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../modules/home-manager/ghostty
  ];
  
  home.packages = with pkgs; [
    yt-dlp
    virt-viewer
  ];

}
