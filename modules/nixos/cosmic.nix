{ config, pkgs, lib, ... }:

{
  services.desktopManager.cosmic.enable = true;

  services.displayManager.cosmic-greeter.enable = true;

  # Only add packages not automatically included by cosmic desktop manager
  environment.systemPackages = with pkgs; [
    # No extra cosmic extensions for now, as they might be outdated
  ];
}
