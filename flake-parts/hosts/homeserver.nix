{ inputs, ... }:
{
  flake.nixosConfigurations.homeserver = {
    system = "x86_64-linux";
    specialArgs = { };
    modules = [
      ../../hosts/homeserver/default.nix
      ../../hosts/common-nixos.nix
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { };
          users.deepwatrcreatur = {
            imports = [
              ../../users/deepwatrcreatur/common.nix
              ../../users/deepwatrcreatur/hosts/homeserver.nix
            ];
          };
          users.root = {
            imports = [
              ../../users/root/common.nix
              ../../users/root/hosts/homeserver.nix
            ];
          };
        };
      }
    ];
  };
}
