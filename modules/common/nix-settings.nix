{ config, lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      # Automatically optimize the Nix store after each build

      experimental-features = [ "nix-command" "flakes" ];

      nixpkgs.config.allowUnfree = true;

      download-buffer-size = 1048576000;

      # Optional: Garbage collection settings
      # Keep 10 generations and run GC weekly
      # You can comment these out if you want to manage GC differently
      keep-outputs = true;
      keep-derivations = true;
      
      # Limit the number of parallel builds (tune for your hardware)
      max-jobs = "auto";
      cores = 0; # Use all available cores

      # Enable trusted users (so your user can run nix commands without sudo)
      trusted-users = [ "root" "@wheel" ];
      
      substituters = [
        "https://cache.nixos.org/"
        "https://cuda-maintainers.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };
}
