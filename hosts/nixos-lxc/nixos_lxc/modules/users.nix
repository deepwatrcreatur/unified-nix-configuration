{ config, lib, pkgs, ... }:

{
  users.users.root.shell = lib.getExe pkgs.bash;

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    shell = lib.getExe pkgs.bash;
    description = "Anwer Khan";
    home = "/home/deepwatrcreatur";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
}
