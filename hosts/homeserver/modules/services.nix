{ config, lib, pkgs, ... }:

{
  sops.secrets.influxdb_password = {
    sopsFile = builtins.path { path = ../secrets/influxdb-secrets.yaml; };
    owner = "influxdb2";
  };

  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = ":8086";
      auth-enabled = true;
      admin-user = "admin";
      admin-password = config.sops.secrets.influxdb_password.path;
    };
  };

  systemd.services.iperf3 = {
    description = "iPerf3 Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.iperf3}/bin/iperf3 --server --bind 0.0.0.0 --port 5201";
      Restart = "always";
      Type = "simple";
    };
  };
}
