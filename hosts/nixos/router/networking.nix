{
  config,
  ...
}:
let
  topology = config.router.topology;
  lanDevice = config.services.router-networking.routedInterfaces.lan.device;
in
{
  imports = [
    ./service-capability.nix
  ];

  networking.hostName = "router";
  networking.domain = topology.domain;

  services.router-kea = {
    enable = true;
    dhcp4 = {
      subnet = topology.networks.lan.cidr;
      gatewayAddress = topology.routerHost.ip;
      dnsServers = [ topology.routerHost.ip ];
      poolRanges = [ { start = "10.10.10.100"; end = "10.10.10.250"; } ];
    };
    ddns = {
      enable = true;
      tsigKeyFile = config.age.secrets.kea-ddns-tsig-key.path;
      tsigKeyName = "kea-ddns";
      forwardZone = topology.domain;
      reverseZone = "10.10.in-addr.arpa";
    };
  };

  # UPnP/NAT-PMP for game consoles and P2P clients.
  # externalInterface and internalIPs are auto-derived.
  services.router-upnp.enable = true;
}
