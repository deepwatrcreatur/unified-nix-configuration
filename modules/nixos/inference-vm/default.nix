{ config, pkgs, lib, inputs, ... }:

{
  # All settings identical for inference1, inference2, inference3
  # DO NOT set networking.hostName here.
  # DO NOT import hardware-configuration.nix here.

  imports = [
    # TBD
  ];

  # Example common settings:
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # Common for VMs

  networking.networkmanager.enable = true;
  networking.useDHCP = true;

  services.openssh.enable = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true; # If all inference VMs need CUDA

  environment.systemPackages = with pkgs; [
    htop vim git curl wget ollama nvtopPackages.full
    cudaPackages.cudatoolkit
  ];

  # Common user setup for inference machines
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "ollama" "video" ]; # Common groups
  };

  # Common services
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  # Common NVIDIA settings if applicable
  hardware.nvidia = {
    modesetting.enable = true;
  };

  system.stateVersion = "24.11"; # Or your current version
}
