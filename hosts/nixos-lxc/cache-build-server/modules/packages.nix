{ config, lib, pkgs, ... }:

{
  # Build server packages
  environment.systemPackages = with pkgs; [
    # System tools
    git
    vim
    htop
    iotop
    lsof
    strace
    
    # Build tools
    gcc
    binutils
    gnumake
    pkg-config
    
    # Archive tools
    gzip
    bzip2
    xz
    
    # Network tools
    curl
    wget
    rsync
    
    # Nix tools
    nix-prefetch-git
    nix-prefetch-github
    nix-index

    # Cache management
    attic-client
    
    # Monitoring
    nvtopPackages.full
  ];
}