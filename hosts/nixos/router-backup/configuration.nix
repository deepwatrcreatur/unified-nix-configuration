{
  config,
  lib,
  inputs,
  ...
}:
let
  topology = config.router.topology;
  domain = topology.domain;
  lanNetwork = topology.networks.lan;
  managementNetwork = topology.networks.management;
  standbyLanIp = "10.10.10.3";
  mkFqdn = label: "${label}.${domain}";
in
{
  imports = [
    (import ../router/role.nix {
      inherit inputs;
      sshTarget = "ssh router-backup";
      wanDevice = "ens27";
      lanDevice = "ens19";
      # Keep the standby LAN identity local to this host definition. Inventory
      # intentionally does not advertise a production IP for router-backup.
      lanIpv4Address = "${standbyLanIp}/${toString lanNetwork.prefixLength}";
      managementIpv4Address = "${topology.backupHost.sshHostname}/${toString managementNetwork.prefixLength}";
      grafanaDomain = mkFqdn "grafana";
      grafanaDataDir = "/var/log/router-backup/grafana";
      prometheusStateDir = "router-backup-prometheus";
      prometheusBindMountPath = "/var/log/router-backup/prometheus";
    })
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  services.router-log-storage.mountPoint = lib.mkForce "/var/log/router-backup";

  host.networking.enableTailscale = lib.mkForce false;
  services.router-tailscale.enable = lib.mkForce false;

  systemd.network.wait-online.enable = lib.mkForce false;

  systemd.services = {
    health-wan-carrier.enable = lib.mkForce false;
    health-wan-ip.enable = lib.mkForce false;
  };

  fileSystems."/srv/pxe" = {
    device = "/dev/disk/by-partlabel/disk-pxe-images-images";
    fsType = "ext4";
    options = [
      "noatime"
      "nofail"
      "x-systemd.automount"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/pxe 0755 root root -"
  ];

  systemd.services.setup-router-backup-pxe-storage = {
    description = "Prepare router-backup PXE storage directories";
    after = [ "srv-pxe.mount" ];
    wants = [ "srv-pxe.mount" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /srv/pxe/images
      mkdir -p /srv/pxe/ipxe
      chmod 0755 /srv/pxe /srv/pxe/images /srv/pxe/ipxe
    '';
  };

  services.iventoy = {
    # Keep the PXE config in tree, but do not run iVentoy on the standby VM
    # while it is intentionally cabled only on the management interface.
    enable = lib.mkForce false;
    isoDir = "/srv/pxe/images";
    openFirewall = false;
  };

  # Keep DNS available on standby, but do not run DHCP/NTP mutation jobs
  # against the local Technitium instance while this node is in disconnected
  # standby or development mode.
  services.router-technitium = {
    scopes = lib.mkForce { };
    dhcpReservations = lib.mkForce { };
    ntpServers = lib.mkForce [ ];
    forceBlockListUpdateOnActivation = lib.mkForce false;
  };

  services.router-firewall = {
    trustedTcpPorts = [
      16000
      26000
    ];
    trustedUdpPorts = [
      69
      4011
    ];
  };

  # Current Proxmox wiring:
  #   ens18 -> management virtio
  #   ens19 -> LAN virtio
  #   ens27 -> WAN passthrough
  #
  # Keep the host leaf aligned to the actual slot names instead of carrying
  # old passthrough-era renames for NICs that no longer exist.

  home-manager.extraSpecialArgs.hostName = lib.mkForce "router-backup";


}
