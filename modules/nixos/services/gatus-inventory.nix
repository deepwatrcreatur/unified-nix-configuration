# modules/nixos/services/gatus-inventory.nix
#
# Automated fleet health and reachability dashboard (Gatus)
# Dynamically populated from lib/hosts.nix inventory and reverse-proxied via Caddy.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.gatus-inventory;

  # Load inventory
  inventory = import cfg.inventoryFile;
  domain = inventory.domain or "deepwatercreature.com";
  hosts = inventory.hosts or { };
  routerHost = hosts.router or { };

  # Classify each host into a descriptive group for Gatus UI
  classifyHost = name: host:
    if lib.hasPrefix "pve-" name then
      "Hypervisors (Proxmox)"
    else if name == "router" || name == "router-backup" then
      "Core Routing & Firewalls"
    else if name == "sw-main" || lib.hasPrefix "ap-" name || lib.hasInfix "airport" name then
      "Network Equipment"
    else if name == "emerald" then
      "Baremetal Servers"
    else if lib.elem name [ "workstation" "phoenix" "lattitude" "framework" ] then
      "Workstations"
    else if lib.elem name [ "418" "420" ] || lib.hasInfix "printer" (host.description or "") || lib.hasInfix "doorbell" (host.description or "") || lib.hasInfix "hp-m477" name then
      "IoT & Peripherals"
    else
      "Containers & Virtual Machines";

  getHostIp = host:
    if (host.ip or null) != null then
      host.ip
    else if (host.sshHostname or null) != null && builtins.match "^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$" host.sshHostname != null then
      host.sshHostname
    else
      null;

  # 1. ICMP ping checks for all reachable hosts with an IP
  hostPingEndpoints = lib.mapAttrsToList (name: host: {
    name = "${name} (${getHostIp host})";
    group = "Hosts: ${classifyHost name host}";
    url = "icmp://${getHostIp host}";
    interval = cfg.pingInterval;
    conditions = [ "[CONNECTED] == true" ];
    alerts = cfg.alerts;
  }) (lib.filterAttrs (_name: host: getHostIp host != null) hosts);

  # 2. HTTP/HTTPS health checks for public ingress services
  # Filter out "status" itself to avoid recursive checks through Caddy.
  publicServices = lib.filter (svc: svc != "status") (routerHost.publicIngressServices or [ ]);

  publicServiceEndpoints = map (svc: {
    name = svc;
    group = "Public Services Ingress";
    url = "https://${svc}.${domain}";
    interval = cfg.httpInterval;
    conditions = [ "[STATUS] < 500" ];
    alerts = cfg.alerts;
  }) publicServices;

  # 3. HTTP health checks for internal admin services
  internalAdminEndpoints = lib.mapAttrsToList (svc: _port: {
    name = svc;
    group = "Internal Admin Services";
    url = "https://${svc}.${domain}";
    interval = cfg.httpInterval;
    conditions = [ "[STATUS] < 500" ];
    alerts = cfg.alerts;
  }) (routerHost.internalAdminServices or { });

in
{
  options.services.gatus-inventory = {
    enable = lib.mkEnableOption "Gatus automated fleet health and reachability dashboard";

    package = lib.mkPackageOption pkgs "gatus" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8085;
      description = "TCP port for Gatus web interface.";
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Listen address for Gatus web interface.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for Gatus port.";
    };

    pingInterval = lib.mkOption {
      type = lib.types.str;
      default = "30s";
      description = "Polling interval for host ICMP ping checks.";
    };

    httpInterval = lib.mkOption {
      type = lib.types.str;
      default = "60s";
      description = "Polling interval for HTTP/HTTPS service health checks.";
    };

    inventoryFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../lib/hosts.nix;
      description = "Path to the lib/hosts.nix file containing host and service definitions.";
    };

    alerts = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "List of alert configurations to attach to endpoints.";
    };

    customEndpoints = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "Additional manual Gatus endpoints.";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra settings to merge into services.gatus.settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.gatus = {
      enable = true;
      package = cfg.package;
      openFirewall = cfg.openFirewall;
      settings = lib.recursiveUpdate {
        web = {
          inherit (cfg) address port;
        };
        ui = {
          title = "Fleet Status | Deepwater Creature";
          header = "Deepwater Homelab Fleet Status";
          description = "Automated health and reachability checks generated from repository inventory";
          default-sort-by = "group";
        };
        endpoints = hostPingEndpoints ++ publicServiceEndpoints ++ internalAdminEndpoints ++ cfg.customEndpoints;
      } cfg.extraSettings;
    };
  };
}
