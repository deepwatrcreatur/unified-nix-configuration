{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
  base = den.mkInventoryHostModule {
    name = "router-backup";
    primaryUser = "deepwatrcreatur";
    primaryUserImports = [
      ../../../users/deepwatrcreatur/hosts/router-backup/default.nix
    ];
    extraImports = [
      # hardware-configuration.nix — generated hardware config. Always keep separate.
      ../../../hosts/nixos/router-backup/hardware-configuration.nix

      # router/caddy.nix — full Caddy config shared with router; imported directly
      # now that the single-line hosts/nixos/router-backup/caddy.nix wrapper has been
      # inlined here. Keep as a separate file (large, shared).
      ../../../hosts/nixos/router/caddy.nix

      # configuration.nix — main composition: imports role.nix with backup-specific
      # args (wanDevice, lanDevice, managementIP, backup-specific Grafana/Prometheus
      # paths, enableLogStorage=false). The authoritative router-backup wiring file.
      ../../../hosts/nixos/router-backup/configuration.nix
    ];
  };
in
# Merge base imports with the hostname override. Deliberately do not import
# hosts/nixos/router/networking.nix here: that file is primary-router policy
# and would duplicate DHCP/DNS state on the backup lab node.
{
  inherit (base) imports;
  networking.hostName = lib.mkForce "router-backup";
}
