# den/aspects/desktop-network-shares.nix
# Strata with network browsing: GVfs provides the smb://, sftp:// and network:// backends,
# Avahi provides mDNS discovery, and wsdd provides WS-Discovery of Windows hosts.
{ ... }:
{ pkgs, ... }:
let
  wsDiscoveryPort = 3702;

  # Hosts answer a WS-Discovery probe with a unicast reply to the probe's source port,
  # and connection tracking does not match that reply to the multicast probe. gvfsd-network
  # spawns wsdd from PATH without a source port, so pin one here that the firewall can allow.
  wsddReplyPort = 37020;
  wsdd = pkgs.writeShellScriptBin "wsdd" ''
    exec ${pkgs.wsdd}/bin/wsdd --source-port ${toString wsddReplyPort} "$@"
  '';
in
{
  programs.strata.enable = true;

  services.gvfs.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  environment.systemPackages = [ wsdd ];

  networking.firewall.allowedUDPPorts = [
    wsDiscoveryPort
    wsddReplyPort
  ];
}
