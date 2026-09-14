{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../modules/nixos/common
  ];

  time.timeZone = "America/Toronto";
  services.openssh.enable = lib.mkDefault true;
  programs.fish.enable = true;
  zramSwap.enable = true;
}
