{ config, pkgs, ... }:

{
  imports = [
    ../../../../modules/home-manager/ghostty
    ../../../../modules/home-manager/gpg-mac.nix
    ../../xbar.nix
  ];

  home.packages = with pkgs; [
    ripgrep
    jq
    yq
    nh
    rclone
    megacmd
    ffmpeg
    yt-dlp
    virt-viewer
  ];

  home.sessionPath = [
    # Add the Homebrew binary path for Apple Silicon.Add commentMore actions
    "/opt/homebrew/bin"

   # Add the user's Nix profile path.
   # Using ${config.home.profileDirectory} is more robust than a hardcoded path.
   "${config.home.profileDirectory}/bin"
  ];
}
