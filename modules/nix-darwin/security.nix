{ config, pkgs, ... }:

{
  security.pam.services.sudo_local.enable = true;
  security.pam.services.screensaver.enable = true;
}
