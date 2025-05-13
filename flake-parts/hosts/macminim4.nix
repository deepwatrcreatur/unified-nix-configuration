{ inputs, ... }:
{
  flake.darwinConfigurations.macminim4 = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs; };
    modules = [
      #../../hosts/macminim4/default.nix
      #../../hosts/common-darwin.nix
      # sops-nix if needed
      inputs.home-manager.darwinModules.home-manager
      {
        home-manager = {
          #useGlobalPkgs = true;
          #useUserPackages = false;
          #extraSpecialArgs = { };
          users.deepwatrcreatur = {
            imports = [
              #../../users/deepwatrcreatur/common.nix
              #../../users/deepwatrcreatur/hosts/macminim4.nix
            ];
          };
        };
      }
    ];
  };
}
