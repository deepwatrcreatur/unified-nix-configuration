{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ../../modules/nix-darwin/rsync-enhanced.nix ];

  services.rsync-enhanced = {
    enable = true;
    logRetentionDays = 7; # Less storage on laptop
    enableMonitoring = true;

    jobs = {
    };

  };
}
