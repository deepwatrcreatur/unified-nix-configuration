# outputs/cache-build-server.nix - NixOS Build Server LXC Container
{ helpers, ... }:
{
  nixosConfigurations.cache-build-server = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos-lxc/cache-build-server;
    isDesktop = false;
    extraModules = [
      # Configure SOPS age keyFile before importing sops-nix module
      {
        sops.age.keyFile = "/var/lib/sops/age/keys.txt";
      }
      ../modules/nixos/lxc-modules.nix  # Use LXC-specific modules instead of regular ones
      ../hosts/nixos-lxc/lxc-systemd-suppressions.nix
      ../hosts/nixos  # Base NixOS config
    ];
  };
}