{ config, pkgs, lib, inputs, ... }: {

  environment.systemPackages = with pkgs; [
    wget
    curl
    neovim
    htop
    btop
    fastfetch
    nmap
    # Add packages needed on *all* your systems
  ];
  system.stateVersion = "24.11"; # Set to the version you initially installed
}
