{ inputs, ... }:
{
  perSystem = { config, pkgs, ... }: {
    # Only for Linux!
    homeConfigurations."deepwatrcreatur@pve-strix" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgs;
      modules = [
        ../../users/deepwatrcreatur/common.nix
        #../../users/deepwatrcreatur/common-linux.nix
        #../../users/deepwatrcreatur/hosts/pve-strix.nix
      ];
    };
  };
}
