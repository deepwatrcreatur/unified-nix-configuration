# outputs/cache-build-server.nix - NixOS Build Server LXC Container
{ helpers, importAllModulesInDir, ... }:
{
  nixosConfigurations.cache-build-server = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos;  # Base NixOS config
    modules = importAllModulesInDir ../hosts/nixos-lxc/nixos_lxc/cache-build-server;
  };
}