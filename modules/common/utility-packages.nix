{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Common utility packages for development, debugging, and system administration
  # Used by: cache-build-server, rustdesk, and other utility hosts
  environment.systemPackages = with pkgs; [
    # System tools
    broot
    git
    hyperfine
    htop
    iotop
    lsof
    procs
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
    netcat-openbsd
    nmap
    openssl

    # Nix tools
    nix-prefetch-git
    nix-prefetch-github
    nix-index

    # Cache management
    attic-client
  ];
}
