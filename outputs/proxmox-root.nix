# outputs/proxmox-root.nix
{ helpers, ... }:
{
  homeConfigurations.proxmox-root = helpers.mkHomeConfig {
    targetSystem = "x86_64-linux";
    hostName = "proxmox-root";
    userPath = ../users/root;
    modules = [ ../users/root/hosts/proxmox ];
    isDesktop = false;
  };
}
