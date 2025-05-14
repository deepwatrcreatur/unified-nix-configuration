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
  perSystem = { config, pkgs, system, ... }: {
    homeConfigurations =
      pkgs.lib.mkIf (pkgs.stdenv.isLinux) (
        pkgs.lib.genAttrs standaloneHosts (host:
          inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = pkgs;
            modules =
              [
                ../../users/deepwatrcreatur/common.nix
                ../../users/deepwatrcreatur/hosts/${host}.nix
              ]
              ++ (if pkgs.stdenv.isLinux then [ ../../users/deepwatrcreatur/common-linux.nix ] else []);
          }
        )
      );
  };
}
