# den/aspects/router-plex-remote-access.nix
# Declarative WAN port forwarding aspect for Plex Media Server.
# Forwards incoming WAN traffic on TCP port 32400 to the Synology DSM VM hosting Plex.
{
  plexHost ? (import ../../lib/hosts.nix).hosts.synology-dsm.ip or "10.10.11.88",
  plexPort ? 32400,
  ...
}:
{ config, lib, ... }:
let
  wanInterface =
    config.services.router-optimizations.interfaces.wan.device or "enp6s17";
in
{
  # Allow forwarded Plex traffic through the firewall from WAN into the LAN
  services.router-firewall.extraWanInRules = ''
    ip daddr ${plexHost} tcp dport ${toString plexPort} limit rate 30/minute log prefix "PLEX-FWD: "
    ip daddr ${plexHost} tcp dport ${toString plexPort} counter accept comment "Plex Media Server forward from WAN"
  '';

  # Logging is rate limited in its own rule: this port is open to the internet, and
  # a limit on the DNAT or accept rule would also limit the traffic.
  # DNAT rule: redirect incoming WAN packets on port 32400 to internal Plex instance
  networking.nftables.tables.plex-remote-access = {
    family = "ip";
    content = ''
      chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        iifname "${wanInterface}" tcp dport ${toString plexPort} limit rate 30/minute log prefix "PLEX-DNAT: "
        iifname "${wanInterface}" tcp dport ${toString plexPort} counter dnat to ${plexHost}:${toString plexPort} comment "Plex Media Server DNAT"
      }
    '';
  };
}
