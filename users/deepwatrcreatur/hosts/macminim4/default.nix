{ config, pkgs, ... }:

{
  imports = [
    ../../../../modules/home-manager/rclone.nix
    ../../../../modules/home-manager/ghostty
    ../../../../modules/home-manager/gpg-mac.nix
    ../../../../modules/home-manager/env-darwin.nix
    ../../../../modules/home-manager/env.nix
    ../../xbar.nix
  ];

  home.packages = with pkgs; [
    bitwarden
    ripgrep
    jq
    yq
    nh
    megacmd
    ffmpeg
    yt-dlp
    virt-viewer
  ];
}
