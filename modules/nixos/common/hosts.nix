# modules/nixos/common/hosts.nix
# Declarative fleet-wide /etc/hosts generation from lib/hosts.nix.
# Ensures all hosts resolve each other and their service aliases (e.g. attic-cache -> emerald)
# across the entire LAN with zero DNS round-trips and resilience against upstream DNS outages.
{ lib, ... }:

let
  hostsData = import ../../../lib/hosts.nix;
in
{
  networking.hosts = lib.mkMerge [
    (lib.mapAttrs' (name: host:
      lib.nameValuePair host.ip (
        lib.unique (
          [
            name
            "${name}.${hostsData.domain}"
          ]
          ++ (host.aliases or [ ])
          ++ (map (alias: "${alias}.${hostsData.domain}") (host.aliases or [ ]))
        )
      )
    ) (lib.filterAttrs (_name: host: (host.ip or null) != null) hostsData.hosts))
  ];
}
