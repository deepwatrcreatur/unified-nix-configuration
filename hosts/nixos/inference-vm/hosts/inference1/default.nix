{ config, lib, pkgs, ... }:

{
  imports = [
    # Hardware configuration (you'll need to copy this from your VM)
    ./hardware-configuration.nix
    
    # Import all inference VM modules
    ../../modules/configuration.nix
    ../../modules/gpu-nvidia.nix
    ../../modules/ollama.nix
    ../../modules/storage.nix
    ../../modules/users.nix
    ../../modules/packages.nix
    ../../modules/nix-config.nix
  ];

  # Host-specific configuration
  networking.hostName = "inference1";
  
  # DHCP with reservation - no static IP needed
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;
}