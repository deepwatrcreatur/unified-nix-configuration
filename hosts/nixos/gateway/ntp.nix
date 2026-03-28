# Local NTP server for the homelab LAN.
#
# chrony syncs from the public pool and serves time to all LAN clients
# (10.10.0.0/16).  DHCP option 42 advertisement is handled by Technitium
# and should be configured via its web UI / API to point at 10.10.10.1.
#
# Why chrony over systemd-timesyncd:
#   - timesyncd is a client only; it cannot serve time to other hosts
#   - chrony handles both roles and has better clock discipline
{ ... }:
{
  services.chrony = {
    enable = true;
    # Use the NTP pool with iburst for fast initial sync
    servers = [
      "0.pool.ntp.org"
      "1.pool.ntp.org"
      "2.pool.ntp.org"
      "3.pool.ntp.org"
    ];
    extraConfig = ''
      # Serve time to all LAN clients
      allow 10.10.0.0/16
      # Step the clock on large offsets rather than slewing (useful after reboots)
      makestep 1.0 3
    '';
  };
}
