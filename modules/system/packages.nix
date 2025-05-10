# modules/system/packages.nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # List your system-wide packages here
    git
    curl
    wget
    gnupg
    htop
    btop
    nmap
    # Add more here
  ];
}

