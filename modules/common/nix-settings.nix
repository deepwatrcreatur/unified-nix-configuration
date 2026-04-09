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
    if config ? home then
      "${config.home.homeDirectory}/.config/git/github-token"
    else
      "/run/secrets/github-token";

  # Detect if we're running in a container (LXC/Docker)
  # boot.isContainer is set by virtualisation/lxc-container.nix and similar
  isContainer = config.boot.isContainer or false;

  # Detect if this is the attic-cache server itself (avoid circular dependency)
  isCacheServer = config.networking.hostName or "" == "attic-cache";
  hasNixCiNetrc = builtins.pathExists nixCiNetrcFile;

  enableCaches = config.myModules.caches.enable or true;
  enableAttic = enableCaches && (config.myModules.caches.enableAttic or true);
  enableNixCi = enableCaches && (config.myModules.caches.enableNixCi or true) && hasNixCiNetrc;

  canUseRemoteBuilder = remoteBuilder.canUse (config.networking.hostName or "");
  daemonExperimentalFeatures =
    [
      "nix-command"
      "flakes"
      "impure-derivations"
      "ca-derivations"
      "pipe-operators"
    ]
    ++ lib.optionals (!isContainer) [ "cgroups" ];
in
{
  imports = [
    ../../den/aspects/nix-caches.nix
  ];

  myModules.caches.enable = lib.mkDefault true;

  # Cache feature toggles (see den/aspects/nix-caches.nix).
  # These allow per-host/aspect control over whether the local Attic
  # cache and the paid nix-ci.com cache are used.

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = daemonExperimentalFeatures;

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
      # Keep the trusted key set aligned with the substituters we enable by
      # default. Otherwise Nix still queries public caches like garnix and
      # nix-community but then ignores their results as untrusted noise.
      (if enableAttic then
        atticCache.defaultTrustedPublicKeys { includeNixCi = enableNixCi; }
        ++ cacheTrust.official
      else
        cacheTrust.official);

    # Access tokens - only on non-cache-server hosts
    access-tokens =
      lib.optionals (!isCacheServer) [
        "${atticCache.serverName}:5001 = /run/nix/attic-token-bearer"
      ];
  };

  # Container-specific settings
  nix.settings.sandbox = lib.mkIf isContainer false;
  nix.settings.use-cgroups = lib.mkIf (!isContainer) true;
  # Keep the daemon environment in sync with the final merged nix.settings value.
  # Some hosts (notably inference VMs) intentionally override experimental
  # features, and duplicating that override here causes conflicting definitions.
  systemd.services.nix-daemon.environment.NIX_CONFIG = lib.mkForce ''
    experimental-features = ${lib.concatStringsSep " " config.nix.settings.experimental-features}
  '';

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
