{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Hardware configuration (you'll need to copy this from your VM)
    ./hardware-configuration.nix

    # Import common inference VM configuration
    ../..
  ];

  # Host-specific configuration
  networking.hostName = "inference3";
}
