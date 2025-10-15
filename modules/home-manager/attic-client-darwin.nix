{ config, lib, ... }:

{
  # Enable attic-client by default on macOS/Darwin systems
  # This overrides the default from the common module
  services.attic-client.enable = lib.mkDefault true;

  # Enable user Nix configuration for Determinate Nix systems
  services.nix-user-config.enable = lib.mkDefault true;
}
