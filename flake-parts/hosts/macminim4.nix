{ inputs, ... }:
{
  flake.darwinConfigurations.macminim4 = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      # ...
      inputs.home-manager.darwinModules.home-manager
      {
        home-manager = {
          users.deepwatrcreatur = {
            imports = [
              ../../users/deepwatrcreatur/common.nix
              ../../users/deepwatrcreatur/common-darwin.nix
              ../../users/deepwatrcreatur/hosts/macminim4.nix
            ];
          };
        };
      }
    ];
  };
}
