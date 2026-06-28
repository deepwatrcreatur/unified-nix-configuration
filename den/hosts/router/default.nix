{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "router";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/router
  ];
  extraImports = [
    # hardware-configuration.nix — generated hardware config. Always keep as a
    # separate import; never inline hardware-generated modules.
    ../../../hosts/nixos/router/hardware-configuration.nix

    # networking.nix — small host-local module: hostname, DNS service (Technitium),
    # NAT=false. Kept separate because it still uses topology config; candidate
    # for inlining once router/configuration.nix is fully migrated.
    ../../../hosts/nixos/router/networking.nix

    # caddy.nix — full Caddy configuration with virtualHosts and ACME.
    # Large and host-specific; should remain a separate file.
    ../../../hosts/nixos/router/caddy.nix

    # disko.nix — declarative disk layout. Keep separate (hardware-adjacent).
    ../../../hosts/nixos/router/disko.nix

    # configuration.nix — main composition: imports role.nix with host-specific
    # args (wanDevice, lanDevice, IPs, domains), adds stable NIC link rules,
    # and configures DNS zones. This is the active router role wiring file.
    # Future work: split into a den aspect once the role.nix API stabilises.
    ../../../hosts/nixos/router/configuration.nix
  ];
}
