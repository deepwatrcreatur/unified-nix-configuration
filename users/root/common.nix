{ inputs, ... }:
{
  # Only for standalone Home Manager configs, if you want them
  perSystem = { config, pkgs, ... }: {
    homeConfigurations."root@pve-strix" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgs;
      extraSpecialArgs = { };
      modules = [
        ../../users/root/common.nix
        # ...other host-specific modules...
      ];
    };
  };
}

