# users/root/hosts/nixos_lxc/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../.. # default config for root
    ./nixos_lxc-justfile.nix
    ./nh.nix
    ../../../../../modules/home-manager/git.nix
    ../../../../../modules/home-manager/gpg-cli.nix
  ];

  # Add packages
  home.packages = [
  ];

  # Configure programs
  programs.bash.enable = true;
}
