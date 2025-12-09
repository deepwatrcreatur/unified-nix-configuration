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
    ./justfile.nix
    ./nh.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/gpg-cli.nix
  ];

  # Disable attic-client for root (no SOPS secrets configured)
  services.attic-client.enable = false;

  # Add packages
  home.packages = [
  ];

  # Configure programs
  programs.bash.enable = true;

}
