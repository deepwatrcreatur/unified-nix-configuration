{
  config,
  lib,
  pkgs,
  ...
}:

{
  # RustDesk server packages (matching cache-build-server toolset)
  environment.systemPackages = with pkgs; [
    # System tools
    vim
    git
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
    netcat-openbsd
    nmap
    openssl

    # Nix tools
    nix-prefetch-git
    nix-prefetch-github
    nix-index

    # Cache management
    attic-client

    # RustDesk server (included automatically via service)
    rustdesk-server
  ];
}
