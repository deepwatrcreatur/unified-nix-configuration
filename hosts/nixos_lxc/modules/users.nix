{ config, lib, pkgs, ... }:

{
  users.users.root.shell = pkgs.nushell;

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    shell = pkgs.nushell;
    description = "Anwer Khan";
    home = "/home/deepwatrcreatur";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
}
