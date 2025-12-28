{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix

    # Import common inference VM configuration
    ../..

    # Enable attic post-build hook
    ../../../../../modules/nixos/attic-post-build-hook.nix
  ];

  # Host-specific configuration
  networking.hostName = "inference1";

  # Enable automatic attic uploads
  services.attic-post-build-hook = {
    enable = true;
    cacheName = "cache-build-server";
    user = "deepwatrcreatur";
  };
}
