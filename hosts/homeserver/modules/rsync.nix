{ config, lib, pkgs, ... }:

{
  imports = [../../../modules/nixos/rsync-enhanced.nix ];
  
  services.rsync-enhanced = {
    logRetentionDays = 7;  # Less storage on laptop
    enableMonitoring = true;

    jobs = {
      };

  };
}
