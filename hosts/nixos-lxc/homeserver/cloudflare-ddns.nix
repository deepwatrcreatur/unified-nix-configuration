# modules/cloudflare-ddns.nix
{
  config,
  pkgs,
  lib,
  ...
}:
let
  apiKeyFile = config.age.secrets."cloudflare-api-key".path;
in
{
  virtualisation.oci-containers.containers.cloudflare-ddns = {
    image = "oznu/cloudflare-ddns:latest";
    autoStart = true;
    environment = {
      ZONE = "deepwatercreature.com";
      PROXIED = "false";
      API_KEY_FILE = "/run/secrets/API_KEY";
    };
    extraOptions = [
      "--dns=1.1.1.1"
      "--dns=1.0.0.1"
      "-v"
      "${apiKeyFile}:/run/secrets/API_KEY:ro"
    ];
  };
}
