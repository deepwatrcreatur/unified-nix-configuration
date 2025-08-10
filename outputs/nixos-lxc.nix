# outputs/nixos-lxc.nix
{ helpers, importAllModulesInDir, ... }:
{
  nixosConfigurations.nixos_lxc = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ./hosts/nixos;  # Base NixOS config
    modules = importAllModulesInDir ./hosts/nixos_lxc/modules;
  };
}
