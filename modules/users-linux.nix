# modules/users.nix
{ config, pkgs, ... }:
{
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    home = "/home/deepwatrcreatur";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.fish;
  };

  users.users.root = {
    shell = pkgs.fish;
  };
}

