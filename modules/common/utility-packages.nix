{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Common utility packages for development, debugging, and system administration
  # Used by: cache-build-server, rustdesk, and other utility hosts
  environment.systemPackages =
    with pkgs;
    [
      # System tools
      broot
      git
      worktrunk
      hyperfine
      htop
      lsof
      procs
      tailspin
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # Linux-only system tools
      pciutils
      iotop
      strace
    ]
    ++ [
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
      nmap
      openssl
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      netcat-openbsd
    ]
    ++ [

      # Nix tools
      nix-prefetch-git
      nix-prefetch-github
      nix-index

      # Cache management
      attic-client
    ];
}
