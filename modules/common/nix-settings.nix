{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Path to GitHub token (works for both user and root contexts)
  githubTokenPath =
    if
      (
        config ? sops
        && config.sops.secrets ? "github-token-root"
        && config.sops.secrets."github-token-root" != null
      )
    then
      config.sops.secrets."github-token-root".path
    else if config ? home then
      "${config.home.homeDirectory}/.config/git/github-token"
    else
      "/root/.config/git/github-token";

  # Detect if we're running in a container (LXC/Docker)
  # boot.isContainer is set by virtualisation/lxc-container.nix and similar
  isContainer = config.boot.isContainer or false;

  # Detect if this is the cache-build-server itself (avoid circular dependency)
  isCacheServer = config.networking.hostName or "" == "cache-build-server";
in
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
      "impure-derivations"
      "ca-derivations"
      "pipe-operators"
    ] ++ lib.optionals (!isContainer) [
      "cgroups" # Process isolation for builds - not available in containers
    ];

    # Performance settings
    download-buffer-size = 1048576000;
    http-connections = 50;
    max-jobs = "auto";
    cores = 0;

    # Build settings
    builders-use-substitutes = true;

    # Garbage collection and derivation settings
    keep-outputs = true;
    keep-derivations = true;

    # UX improvements
    show-trace = true;
    warn-dirty = false;
    flake-registry = "";

    trusted-users = [
      "root"
      "@wheel"
    ] ++ lib.optionals (!isContainer) [
      "@build"
      "@admin"
      "deepwatrcreatur"
    ];

    # Substituters - exclude local cache on the cache server itself to avoid circular dependency
    substituters = lib.optionals (!isCacheServer) [
      "http://cache-build-server:5001/cache-local"
    ] ++ [
      "https://cache.nixos.org/"
      "https://cuda-maintainers.cachix.org"
      "https://cache.garnix.io/"
      "https://nix-community.cachix.org/"
      "https://hyprland.cachix.org/"
    ];

    trusted-public-keys = [
      "cache-local:63xryK76L6y/NphTP/iS63yiYqldoWvVlWI0N8rgvBw="
      "cache.local:92faFQnuzuYUJ4ta3EYpqIaCMIZGenDoaPktsBucTe4="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];

    # Access tokens - only on non-cache-server hosts
    access-tokens = lib.optionals (!isCacheServer) [
      "cache-build-server:5001 = /run/nix/attic-token-bearer"
    ]
    # Only try to read GitHub token if it's a SOPS secret (avoid file system access during evaluation)
    ++ lib.optionals (
      config ? sops
      && config.sops.secrets ? "github-token-root"
      && config.sops.secrets."github-token-root" != null
    ) [
      "github.com=${builtins.readFile config.sops.secrets."github-token-root".path}"
    ];
  };

  # Container-specific settings
  nix.settings.sandbox = lib.mkIf isContainer false;
  nix.settings.use-cgroups = lib.mkIf (!isContainer) true;
}
