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
      lsof
      procs
      tailspin
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # Linux-only system tools
      pciutils
      iotop
      iodyne
      strace
      wl-clipboard
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
      lazyrsync
      mosh
      nmap
      openssl
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      netcat-openbsd
      lightpanda  # Headless browser for AI agents
      ethtool
      tcpdump
      # iputils no longer ships ping6; resolve `ping` via PATH so NixOS's
      # capability wrapper (/run/wrappers/bin/ping) is used. macOS has /sbin/ping6.
      (writeShellScriptBin "ping6" ''exec ping -6 "$@"'')
    ]
    ++ [
      # Nix tools
      nix-prefetch-git
      nix-prefetch-github
      nix-index

      # Secrets management tools are in ./secrets-management.nix

      # Cache management
      attic-client
    ];
}
