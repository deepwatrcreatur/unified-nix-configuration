{ config, pkgs, ... }:

{
  security.pam.services.sudo_local.enable = true;
}
