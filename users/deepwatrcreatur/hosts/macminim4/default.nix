{ config, pkgs, ... }:

{
  imports = [
    ../../../../modules/home-manager/rclone.nix
    ../../../../modules/home-manager/ghostty
    #../../../../modules/home-manager/zed.nix
    ../../../../modules/home-manager/gpg-mac.nix
    ../../../../modules/home-manager/env-darwin.nix
    ./nh.nix
    ./karabiner.nix
    ../../xbar.nix
    ../../rbw.nix
  ];

  home.packages = with pkgs; [
    bitwarden
    megacmd
    ffmpeg
    ghostty-bin
    input-leap
    yt-dlp
    virt-viewer
  ];
}
