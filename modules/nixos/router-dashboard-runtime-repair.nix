{
  config,
  inputs,
  lib,
  options,
  pkgs,
  ...
}:
let
  hasRouterDashboard = lib.hasAttrByPath [ "services" "router-dashboard" ] options;
  cfg = if hasRouterDashboard then config.services.router-dashboard else { enable = false; };
  keaEnabled = config.services.router-kea.enable or false;
  keaPool = if keaEnabled && (config.services.router-kea.dhcp4.poolRanges or [ ]) != [ ]
    then builtins.head config.services.router-kea.dhcp4.poolRanges
    else { start = ""; end = ""; };
  fail2banSnapshotFile = "/run/router-dashboard/fail2ban-status.json";
  keaLeaseSnapshotFile = "/run/router-dashboard/kea-dhcp4.leases";
  routerDashboardApiWrapper = ../../scripts/router-dashboard-api-wrapper.py;
  fail2banSnapshotScript = ../../scripts/router-dashboard-fail2ban-snapshot.py;
  keaLeaseSnapshotScript = pkgs.writeShellScript "router-dashboard-kea-lease-snapshot" ''
    set -euo pipefail

    source_file="/var/lib/kea/dhcp4.leases"
    target_file="${keaLeaseSnapshotFile}"

    if [ ! -f "$source_file" ]; then
      echo "Kea lease file not found at $source_file" >&2
      exit 1
    fi

    install -D -m 0640 -o root -g router-dashboard "$source_file" "$target_file"
  '';
in
{
  config = lib.mkIf (hasRouterDashboard && cfg.enable) {
    assertions = [
      {
        assertion = builtins.hasAttr "router-dashboard" config.users.groups;
        message = ''
          router-dashboard-runtime-repair expects a router-dashboard group so
          /run/router-dashboard and the Cloudflare token can be shared safely.
        '';
      }
    ];

    systemd.services.router-dashboard.environment = {
      DASHBOARD_UPSTREAM_SERVER = "${inputs.nix-router-optimized.outPath}/modules/router-dashboard/api/server.py";
      DASHBOARD_INTERFACES = builtins.toJSON cfg.interfaces;
      DASHBOARD_FAIL2BAN_STATUS_FILE = fail2banSnapshotFile;
      DASHBOARD_CLOUDFLARE_TOKEN_FILE = config.age.secrets.cloudflare-api-key.path;
      DASHBOARD_DHCP_PROVIDER = if keaEnabled then "kea" else "technitium";
      DASHBOARD_KEA_LEASE_FILE = if keaEnabled then keaLeaseSnapshotFile else "";
      DASHBOARD_KEA_DHCP = if keaEnabled then builtins.toJSON {
        scope = "LAN";
        title = "Kea DHCP";
        interfaces = config.services.router-kea.dhcp4.interfaces or [ ];
        subnet = config.services.router-kea.dhcp4.subnet or "";
        startAddress = keaPool.start;
        endAddress = keaPool.end;
      } else "{}";
    };

    systemd.services.router-dashboard.serviceConfig.ExecStart = lib.mkForce "${pkgs.python3}/bin/python3 ${routerDashboardApiWrapper}";
    systemd.services.router-dashboard.serviceConfig.ReadOnlyPaths = [
      "/run/router-dashboard"
    ];

    systemd.tmpfiles.rules = [
      "d /run/router-dashboard 0750 root router-dashboard -"
    ];

    systemd.services.router-dashboard-fail2ban-snapshot = lib.mkIf config.services.fail2ban.enable {
      description = "Refresh router dashboard fail2ban status snapshot";
      after = [ "fail2ban.service" ];
      requires = [ "fail2ban.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.python3}/bin/python3 ${fail2banSnapshotScript}";
        # Keep root because fail2ban-client needs access to the control socket,
        # but tighten the sandbox around the snapshot writer itself.
        User = "root";
        Group = "root";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/run/router-dashboard" ];
        ProtectClock = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };
      environment = {
        DASHBOARD_FAIL2BAN_CLIENT = "${pkgs.fail2ban}/bin/fail2ban-client";
        DASHBOARD_FAIL2BAN_STATUS_FILE = fail2banSnapshotFile;
        DASHBOARD_FAIL2BAN_STATUS_GROUP = "router-dashboard";
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.timers.router-dashboard-fail2ban-snapshot = lib.mkIf config.services.fail2ban.enable {
      description = "Refresh router dashboard fail2ban status snapshot periodically";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "30s";
        Unit = "router-dashboard-fail2ban-snapshot.service";
      };
    };

    systemd.services.router-dashboard-kea-lease-snapshot = lib.mkIf keaEnabled {
      description = "Refresh router dashboard Kea lease snapshot";
      after = [ "kea-dhcp4-server.service" ];
      requires = [ "kea-dhcp4-server.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = keaLeaseSnapshotScript;
        User = "root";
        Group = "root";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/run/router-dashboard" ];
        ProtectClock = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };
      wantedBy = [ "multi-user.target" ];
    };

    systemd.timers.router-dashboard-kea-lease-snapshot = lib.mkIf keaEnabled {
      description = "Refresh router dashboard Kea lease snapshot periodically";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "30s";
        Unit = "router-dashboard-kea-lease-snapshot.service";
      };
    };
  };
}
