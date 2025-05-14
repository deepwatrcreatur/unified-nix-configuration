{ inputs, ... }:
{
  perSystem = { config, pkgs, system, ... }: {
    homeConfigurations =
      pkgs.lib.mkIf (system == "x86_64-linux") {
        "deepwatrcreatur@pve-strix" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          modules = [
            ../../users/deepwatrcreatur/common.nix
            ../../users/deepwatrcreatur/common-linux.nix
            ../../users/deepwatrcreatur/hosts/pve-strix.nix
          ];
        };
      };
  };
}

