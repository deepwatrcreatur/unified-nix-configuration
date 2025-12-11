{ config, lib, ... }:

{
  # attic-client service is only available on NixOS/Linux systems
  # On macOS, we use the attic-client package directly without a service
  programs.attic-client.enable = lib.mkDefault true;

  # Enable user Nix configuration for Determinate Nix systems
  services.nix-user-config.enable = lib.mkDefault true;
}
