{ config, lib, pkgs, ... }:

{
  # Nix configuration with build cache and remote building
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      download-buffer-size = 1048576000;

      # Binary caches
      substituters = [ 
        "https://cache.nixos.org/" 
        "https://cuda-maintainers.cachix.org" 
        "http://cache.deepwatercreature.com"
      ];
      
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "cache.deepwatercreature.com-1:n7+NSSNvxLJBRpjB8ai2zsVtK1L9mnFtEnulbd4/lUY="
      ];

      trusted-users = [ "root" "@wheel" ];
    };

    # Remote building configuration
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "cache.deepwatercreature.com";
        system = "x86_64-linux";
        maxJobs = 8;
        speedFactor = 2;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        sshUser = "deepwatrcreatur";
        sshKey = "/root/.ssh/nix-remote";
      }
    ];
  };
}