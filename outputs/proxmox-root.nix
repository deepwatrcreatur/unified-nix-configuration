# outputs/proxmox-root.nix
{ helpers, ... }:
{
  homeConfigurations.proxmox-root = helpers.mkHomeConfig {
    system = "x86_64-linux";
    userPath = ../users/root/hosts/proxmox;
    isDesktop = false;
  };
}
