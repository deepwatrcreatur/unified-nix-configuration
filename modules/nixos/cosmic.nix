{ config, pkgs, lib, ... }:

{
  services.xserver.enable = true;

  services.xserver.desktopManager.cosmic.enable = true;

  services.xserver.displayManager.gdm = {
    enable = true;
    defaultSession = "cosmic";
  };

  # Only add packages not automatically included by cosmic desktop manager
  environment.systemPackages = with pkgs; [
    cosmic-ext-tweaks  # Extension for additional COSMIC tweaks
    cosmic-ext-ctl     # Control utility for COSMIC extensions
  ];
}
