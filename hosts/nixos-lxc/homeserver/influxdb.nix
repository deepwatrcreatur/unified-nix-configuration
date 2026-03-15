# modules/nixos/services/influxdb.nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Secret defined in ./agenix.nix
  # age.secrets.influxdb-password is expected to exist

  services.influxdb2 = {
    enable = true;
    settings = {
      http-bind-address = ":8086";
      auth-enabled = true;
      admin-user = "admin";
      admin-password = config.age.secrets.influxdb-password.path;
    };
  };
}
