# outputs/ansible.nix
{
  helpers,
  inputs,
  homeManagerModuleArgs,
  ...
}:
{
  #nixosConfigurations.ansible = helpers.mkNixosSystem {
  #  system = "x86_64-linux";
  #  hostPath = ../hosts/nixos-lxc/ansible;
  #  extraModules = [
  #    ../hosts/nixos-lxc/ansible/sops.nix
  #    ({ config, lib, inputs, ... }: {
  #      home-manager.users.ansible = {
  #        imports = [ ../modules/home-manager ];
  #        home.stateVersion = "24.11";
  #        sops.age.keyFile = "/var/lib/sops/age/key.txt";
  #      };
  #      home-manager.extraSpecialArgs = homeManagerModuleArgs;
  #    })
  #  ];
  #};
}
