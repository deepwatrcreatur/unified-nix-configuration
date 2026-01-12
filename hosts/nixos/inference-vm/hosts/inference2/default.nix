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
  ];

  boot.growPartition = true;

  # Host-specific configuration
  networking.hostName = "inference2";
}
