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

      # router/networking.nix — shared DNS/NAT config; imported directly now that
      # the thin hosts/nixos/router-backup/networking.nix wrapper has been inlined
      # here. The hostname override below replaces that wrapper.
      ../../../hosts/nixos/router/networking.nix

      # caddy.nix — Caddy config for router-backup. Keep separate (large, host-local).
      ../../../hosts/nixos/router-backup/caddy.nix

      # configuration.nix — main composition: imports role.nix with backup-specific
      # args (wanDevice, lanDevice, managementIP, backup-specific Grafana/Prometheus
      # paths, enableLogStorage=false). The authoritative router-backup wiring file.
      ../../../hosts/nixos/router-backup/configuration.nix
    ];
  };
in
# Merge base imports with the hostname override that was previously in the
# now-deleted hosts/nixos/router-backup/networking.nix wrapper.
{
  inherit (base) imports;
  # router/networking.nix sets hostName = "router"; override for this host.
  networking.hostName = lib.mkForce "router-backup";
}
