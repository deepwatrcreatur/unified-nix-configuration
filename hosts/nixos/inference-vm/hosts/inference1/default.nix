{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    
    # Import common inference VM configuration
    ../..
  ];

  # Host-specific configuration
  networking.hostName = "inference1";
}
