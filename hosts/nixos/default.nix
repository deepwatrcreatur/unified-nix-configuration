{
  config,
  pkgs,
  lib,
  ...
}:

{
  time.timeZone = "America/Toronto";
  services.openssh.enable = lib.mkDefault true;
  programs.fish.enable = true;
  zramSwap.enable = true;

  # Home Manager configuration
  home-manager.backupFileExtension = "backup";
}
