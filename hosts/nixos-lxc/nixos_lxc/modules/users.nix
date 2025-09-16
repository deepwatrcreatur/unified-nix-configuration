{ config, lib, pkgs, ... }:

{
  users.users.root.shell = pkgs.fish;

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "Anwer Khan";
    home = "/home/deepwatrcreatur";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
}
