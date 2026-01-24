{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Common utility packages for debugging and system administration
  # Development tools are in dev-tools.nix
  environment.systemPackages =
    with pkgs;
    [
      # System tools
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
