# Common settings applied to ALL machines defined in flake.nix
{ config, pkgs, lib, inputs, ... }: {
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true; # Recommended: use key-based auth
    settings.KbdInteractiveAuthentication = true;
  };
}

