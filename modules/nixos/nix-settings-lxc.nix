{ config, lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        # Remove newer experimental features that might not be supported in LXC
      ];
      
      # Performance settings
      download-buffer-size = 1048576000;
      http-connections = 50;
      max-jobs = "auto";
      cores = 0;
      
      # Build settings (remove newer settings)
      builders-use-substitutes = true;
      # Removed: use-cgroups, lazy-trees - not supported in older Nix versions
      # auto-optimise-store = false; # Uncomment if needed for very old Nix versions
      
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
      ];
      
      substituters = [
        "https://cache.nixos.org/"
        "https://cuda-maintainers.cachix.org"
        "https://cache.garnix.io/"
        "https://nix-community.cachix.org/"
        "https://hyprland.cachix.org/"
      ];
      
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };
}