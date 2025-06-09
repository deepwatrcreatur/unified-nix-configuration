# This is a SYSTEM-LEVEL module for nix-darwin or NixOS.
# It finds the main user and sets their Home Manager PATH.
{ lib, config, ... }:

let
  mainUser = lib.findFirst (user: user.name != "root" && user.home != null) null (lib.attrValues config.users.users);
in
lib.mkIf (mainUser != null) {
  home-manager.users.${mainUser.name}.home.sessionPath = [
    #"${mainUser.home}/.nix-profile/bin"
    "/opt/homebrew/bin"
  ];
}
