# DNS zone configuration for the homelab.
# Generated from lib/hosts.nix - single source of truth
let
  hostsData = import ../../../lib/hosts.nix;

  # Filter hosts that should be in DNS
  dnsHosts = builtins.removeAttrs
    (builtins.mapAttrs (name: host: host // { inherit name; }) hostsData.hosts)
    (builtins.attrNames (builtins.filter (name:
      !(hostsData.hosts.${name}.includeDns or true) || hostsData.hosts.${name}.ip or null == null
    ) (builtins.attrNames hostsData.hosts)));

  # Transform hosts to DNS zone format
  hostsToDnsRecords = builtins.listToAttrs (
    builtins.filter (x: x != null) (
      builtins.map (name:
        let host = hostsData.hosts.${name}; in
        if (host.includeDns or true) && (host.ip or null) != null
        then {
          inherit name;
          value =
            let
              # Combine machine-identity aliases and public-service names — both
              # become CNAME records pointing at this host in the DNS zone.
              # internalAdminServices also become internal CNAMEs.
              allAliases =
                (host.aliases or [])
                ++ (host.publicIngressServices or host.services or [])
                ++ (builtins.attrNames (host.internalAdminServices or {}));
            in
            {
              ipv4 = host.ip;
              ipv6 = host.ipv6 or null;
            } // (if allAliases != [] then { aliases = allAliases; } else {});
        }
        else null
      ) (builtins.attrNames hostsData.hosts)
    )
  );

in {
  zones = {
    "${hostsData.domain}" = {
      # Static host records - generated from lib/hosts.nix
      hosts = {
        # Root domain points to router
        "@" = {
          ipv4 = hostsData.hosts.router.ip;
          ipv6 = null;
        };
      } // hostsToDnsRecords;

      # Additional CNAME aliases (for hosts not in hosts.nix)
      aliases = {
        # "www" = "router";
        # "mail" = "router";
        "scrypted" = "router";
      };
    };
  };
}
