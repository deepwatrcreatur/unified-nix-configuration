# modules/nixos/services/influxdb.nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  sops.secrets.influxdb_password = {
    sopsFile = builtins.path { path = ./secrets/influxdb-secrets.yaml; };
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
}
