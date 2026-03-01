{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./justfile.nix
    ./nh.nix
    ./proxmox-shell-extra.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/gpg-cli.nix
    # Selectively import only essential modules to avoid activation issues
    ../../../../modules/home-manager/secrets-activation.nix
    ../../../../modules/home-manager/common/nix-user-config.nix
    ../../../../modules/home-manager/common/attic-client.nix
    ../../../../modules/home-manager/common/fish.nix
    ../../../../modules/home-manager/common/starship.nix
    # Avoid importing tool-aliases and bat modules that break activation
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  nix.package = pkgs.nix;

  home.packages = with pkgs; [
    proxmenux
  ];
  # Determinate Nix manages `/etc/nix/nix.conf`; we only add user extras.
  services.nix-user-config.enable = true;

  # Allow root to manage Home Manager
  programs.home-manager.enable = true;

  # Enable attic-client for binary cache access
  programs.attic-client.enable = true;

}
