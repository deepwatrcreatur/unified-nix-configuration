# ./hosts/nixos-lxc/homeserver/agenix.nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Agenix secrets configuration for homeserver
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  age.secrets = {
    "cloudflare-api-key" = {
      file = ../../../secrets-agenix/cloudflare-api-key.age;
      mode = "0400";
    };
    "influxdb-password" = {
      file = ../../../secrets-agenix/influxdb-password.age;
      owner = "influxdb2";
      mode = "0400";
    };
    "kasa-influxdb-token" = {
      file = ../../../secrets-agenix/kasa-influxdb-token.age;
      mode = "0400";
    };
    "kasa-tplink-password" = {
      file = ../../../secrets-agenix/kasa-tplink-password.age;
      mode = "0400";
    };
  };
}
