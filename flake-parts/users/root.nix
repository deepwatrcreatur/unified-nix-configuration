# flake-parts/users/root.nix
{ inputs, ... }:
{
#  perSystem = { config, pkgs, ... }: {
#    homeConfigurations."root@pve-strix" = inputs.home-manager.lib.homeManagerConfiguration {
#      pkgs = pkgs;
#      extraSpecialArgs = { };
#      modules = [
#        ../../users/root/common.nix
#        # ...other host-specific modules...
#      ];
#    };
#  };
}

