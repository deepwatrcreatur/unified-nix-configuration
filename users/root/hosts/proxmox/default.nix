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
    ../../../../modules/home-manager
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
