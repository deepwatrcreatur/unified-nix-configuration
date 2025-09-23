{ config, pkgs, lib, ... }:

{
  time.timeZone = "America/Toronto";
  services.openssh.enable = lib.mkDefault true;
  programs.fish.enable = true;
  boot.zramSwap.enable = true;
}

