{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
  base = den.mkInventoryHostModule {
    name = "elitedesk";
    primaryUser = "deepwatrcreatur";
    primaryUserImports = [
      ../../../users/deepwatrcreatur/hosts/elitedesk/default.nix
    ];
    extraImports = [
      # hardware-configuration.nix: hardware config. Keep separate.
      ../../../hosts/nixos/elitedesk/hardware-configuration.nix

      # Shared router-service capability (DNS/NTP/NAT wiring) without
      # router/networking.nix's hostname.
      ../../../hosts/nixos/router/service-capability.nix

      # Shared Caddy config.
      ../../../hosts/nixos/router/caddy.nix

      # Router role in standby mode, NIC pinning, disks.
      ../../../hosts/nixos/elitedesk/configuration.nix
    ];
  };
in
{
  inherit (base) imports;
  # SECURITY: Keep NixCI disabled and its credential undeclared on router hosts.
  myModules.caches.enableNixCi = false;
  networking.hostName = lib.mkForce "elitedesk";
  networking.domain = lib.mkDefault (import ../../../lib/hosts.nix).domain;
}
