{ inputs, ... }:
let
  standaloneHosts = [
    "pve-strix"
    "homeserver"
    #"ansible"
    #"inference1"
    #"inference2"
    #"inference3"
  ];
in
{
perSystem = { config, pkgs, system, ... }:
    if pkgs.stdenv.isLinux then {
      homeConfigurations = pkgs.lib.genAttrs standaloneHosts (host:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          modules = [
            ../../users/deepwatrcreatur/common.nix
            ../../users/deepwatrcreatur/common-linux.nix
            ../../users/deepwatrcreatur/hosts/${host}.nix
          ];
        }
      );
    } else {};
}
