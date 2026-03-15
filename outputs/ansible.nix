# outputs/ansible.nix
{
  helpers,
  inputs,
  homeManagerModuleArgs,
  ...
}:
{
  nixosConfigurations.ansible = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos-lxc/ansible;
    extraModules = [
      # sops.nix disabled - migrated to agenix
      (
        {
          config,
          lib,
          inputs,
          ...
        }:
        {
          # Agenix identity for secrets
          age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          home-manager.users.ansible = {
            imports = [ ../modules/home-manager ];
            home.stateVersion = "24.11";
          };
          home-manager.extraSpecialArgs = homeManagerModuleArgs;
        }
      )
    ];
  };
}
