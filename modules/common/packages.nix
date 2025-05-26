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
}
