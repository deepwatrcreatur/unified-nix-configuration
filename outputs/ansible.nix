# outputs/ansible.nix
{ helpers, inputs, homeManagerModuleArgs, ... }:
{
  nixosConfigurations.ansible = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ./hosts/ansible;  # You'll need to create this
    extraModules = [
      ({ config, lib, inputs, ... }: {
        home-manager.users.ansible = {
          imports = [ ./modules ];
        };
        home-manager.extraSpecialArgs = homeManagerModuleArgs;
      })
    ];
  };
}
