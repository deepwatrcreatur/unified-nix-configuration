# Common settings applied to ALL machines defined in flake.nix
{ config, pkgs, lib, inputs, ... }: {
  # Systemd journal settings
  services.journald.extraConfig = ''
    SystemMaxUse=50M
    RuntimeMaxUse=50M
  '';
}

