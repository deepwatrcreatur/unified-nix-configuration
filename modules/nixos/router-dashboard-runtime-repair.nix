{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.router-dashboard;
  fail2banSnapshotFile = "/run/router-dashboard/fail2ban-status.json";
  routerDashboardApiWrapper = ../../scripts/router-dashboard-api-wrapper.py;
  fail2banSnapshotScript = ../../scripts/router-dashboard-fail2ban-snapshot.py;
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.router-dashboard.environment = {
      DASHBOARD_UPSTREAM_SERVER = "${inputs.nix-router-optimized.outPath}/modules/router-dashboard/api/server.py";
      DASHBOARD_INTERFACES = builtins.toJSON cfg.interfaces;
      DASHBOARD_FAIL2BAN_STATUS_FILE = fail2banSnapshotFile;
      DASHBOARD_CLOUDFLARE_TOKEN_FILE = config.age.secrets.cloudflare-api-key.path;
    };

    systemd.services.router-dashboard.serviceConfig.ExecStart = lib.mkForce "${pkgs.python3}/bin/python3 ${routerDashboardApiWrapper}";

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
        User = "root";
        Group = "root";
        PrivateTmp = false;
      };
      environment = {
        DASHBOARD_FAIL2BAN_CLIENT = "${pkgs.fail2ban}/bin/fail2ban-client";
        DASHBOARD_FAIL2BAN_STATUS_FILE = fail2banSnapshotFile;
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
