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
  fail2banSnapshotFile = "/run/router-dashboard/fail2ban-status.json";
  routerDashboardApiWrapper = ../../scripts/router-dashboard-api-wrapper.py;
  fail2banSnapshotScript = ../../scripts/router-dashboard-fail2ban-snapshot.py;
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
  };
}
