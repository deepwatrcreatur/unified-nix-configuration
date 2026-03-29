{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  remoteBuilder = import ../../lib/remote-builder.nix { inherit pkgs; };
  cacheTrust = import ../../lib/cache-trust.nix;
  atticCache = import ../../lib/attic-cache.nix;
  nixCiNetrcFile = ../../secrets-agenix/nix-ci-netrc.age;

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

  # Detect if this is the attic-cache server itself (avoid circular dependency)
  isCacheServer = config.networking.hostName or "" == "attic-cache";
  hasNixCiNetrc = builtins.pathExists nixCiNetrcFile;

  canUseRemoteBuilder = remoteBuilder.canUse (config.networking.hostName or "");
in
{
  myModules.caches.enable = lib.mkDefault true;

  # Cache feature toggles (see den/aspects/nix-caches.nix).
  # These allow per-host/aspect control over whether the local Attic
  # cache and the paid nix-ci.com cache are used.
  let
    enableCaches = config.myModules.caches.enable or true;
    enableAttic = enableCaches && (config.myModules.caches.enableAttic or true);
    enableNixCi = enableCaches && (config.myModules.caches.enableNixCi or true) && hasNixCiNetrc;
  in

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
      "impure-derivations"
      "ca-derivations"
      "pipe-operators"
    ]
    ++ lib.optionals (!isContainer) [
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
    ]
    ++ lib.optionals (!isContainer) [
      "@build"
      "@admin"
      "deepwatrcreatur"
    ];

    # Substituters - exclude local cache on the cache server itself to avoid circular dependency
    substituters =
      (if !isCacheServer then
        if enableAttic then
          atticCache.defaultSubstituters { includeNixCi = enableNixCi; }
        else
          # Fallback when Attic is disabled: keep using cache.nixos.org
          [ atticCache.nixosCacheUrl ]
      else
        [ ])
      ++ [
        "https://cache.numtide.com" # llm-agents (claude-code, codex, rtk, etc.)
        "https://cuda-maintainers.cachix.org"
        "https://cache.garnix.io/"
        "https://nix-community.cachix.org/"
        "https://hyprland.cachix.org/"
      ];

    trusted-public-keys =
      # When Attic is disabled, fall back to the full set of official keys so
      # cache.nixos.org remains usable.
      (if enableAttic then
        atticCache.defaultTrustedPublicKeys { includeNixCi = enableNixCi; }
      else
        cacheTrust.official);

    # Access tokens - only on non-cache-server hosts
    access-tokens =
      lib.optionals (!isCacheServer) [
        "${atticCache.serverName}:5001 = /run/nix/attic-token-bearer"
      ]
      # Only try to read GitHub token if it's a SOPS secret (avoid file system access during evaluation)
      ++
        lib.optionals
          (
            config ? sops
            && config.sops.secrets ? "github-token-root"
            && config.sops.secrets."github-token-root" != null
          )
          [
            "github.com=${builtins.readFile config.sops.secrets."github-token-root".path}"
          ];
  };

  # Container-specific settings
  nix.settings.sandbox = lib.mkIf isContainer false;
  nix.settings.use-cgroups = lib.mkIf (!isContainer) true;

  # Remote building configuration
  nix.distributedBuilds = lib.mkIf canUseRemoteBuilder true;
  nix.buildMachines = lib.mkIf canUseRemoteBuilder [
    {
      hostName = "10.10.11.39"; # attic-cache
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      sshUser = "deepwatrcreatur";
      sshKey = remoteBuilder.keyPath;
    }
  ];
}
