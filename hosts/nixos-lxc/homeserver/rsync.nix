{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ../../../modules/nixos/rsync-enhanced.nix ];

  services.rsync-enhanced = {
    enable = true;
    logRetentionDays = 7; # Less storage on laptop
    enableMonitoring = true;

    jobs = {
    };

  };
}
