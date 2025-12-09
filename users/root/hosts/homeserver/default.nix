# users/root/hosts/homeserver/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../.. # default config for root
    ./homeserver-justfile.nix
    ./nh.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/gpg-cli.nix
    ../../../../modules/home-manager/linuxbrew.nix
  ];

  # Add packages
  home.packages = [
  ];

  # Configure programs
  programs.bash.enable = true;
}
