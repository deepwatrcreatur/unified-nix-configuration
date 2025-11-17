{ config, lib, pkgs, ... }:

let
  # Path to GitHub token (works for both user and root contexts)
  githubTokenPath = if config ? home
    then "${config.home.homeDirectory}/.config/git/github-token"
    else "/root/.config/git/github-token";
in
{
  nixpkgs.config.allowUnfree = true;
  
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "impure-derivations"
        "ca-derivations"
        "cgroups"          # Process isolation for builds
        "pipe-operators"   # Nice syntax sugar you're using
      ];
      
      # Performance settings
      download-buffer-size = 1048576000;
      http-connections = 50;            # More concurrent downloads
      max-jobs = "auto";
      cores = 0; # Use all available cores
      
      # Build settings
      builders-use-substitutes = true;  # Builders can use binary caches
      use-cgroups = true;               # Better build isolation
      lazy-trees = true;                # Better flake performance
      
      # Garbage collection and derivation settings
      keep-outputs = true;
      keep-derivations = true;
      
      # UX improvements
      show-trace = true;                # Better error messages
      warn-dirty = false;               # Less noisy for development
      flake-registry = "";              # Disable global flake registry
      
      trusted-users = [
        "root"
        "@wheel"
        "@build"    # Build users
        "@admin"    # Admin users (macOS)
        "deepwatrcreatur"  # Explicit user trust
      ];
      
      substituters = [
        "http://cache-build-server:5001/cache-local"           # Attic cache (preferred)
        "http://cache.deepwatercreature.com:5000/"             # Legacy nix-serve
        "https://cache.nixos.org/"
        "https://cuda-maintainers.cachix.org"
        "https://cache.garnix.io/"
        "https://nix-community.cachix.org/"
        "https://hyprland.cachix.org/"
      ];
      
      trusted-public-keys = [
        "cache.deepwatercreature.com:o95LnlK2Xz/aaFtygmgB0P4gA8WBVnFZc0gx1WyorBw="
        "cache-local:63xryK76L6y/NphTP/iS63yiYqldoWvVlWI0N8rgvBw="  # Attic cache-local public key
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];

      access-tokens = [
        "cache-build-server:5001 = /run/nix/attic-token-bearer"
        "github.com = ${githubTokenPath}"
      ];
    };
  };
}
