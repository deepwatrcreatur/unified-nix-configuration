# users/root/hosts/proxmox-justfile.nix
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = [ pkgs.just ];

  home.file.".justfile".source = ./justfile;
}
