
# hosts/homeserver/modules/home-assistant.nix
{ config, lib, pkgs, ... }:

{
  # SOPS secrets for Home Assistant
  sops.secrets.REOLINK_CAMERA_PASSWORD = {
    sopsFile = builtins.path { path = ../secrets/reolink-secrets.yaml; };
    owner = "hass";
    group = "hass";
    mode = "0440";
  };

  # Ensure hass user and group are configured
  users.users.hass = {
    isSystemUser = true; # Required for Home Assistant service user
    group = "hass";
    extraGroups = [ "keys" ]; # For SOPS secrets access
  };

  users.groups.hass = {}; # Create hass group if it doesn't exist

  # Systemd service overrides for Home Assistant
  systemd.services."home-assistant" = {
    wants = [ "sops-nix.service" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      LoadCredential = lib.mkForce null; # Avoid conflicts with EnvironmentFile
      EnvironmentFile = config.sops.secrets.REOLINK_CAMERA_PASSWORD.path;
    };
  };

  # Home Assistant configuration
  modules.homeAssistant = {
    enable = true;
    latitude = "40.7128";
    longitude = "-74.0060";
    timeZone = "America/Toronto";
    unitSystem = "metric";
    reolink = {
      enable = true;
      cameras = {
        "418" = {
          host = "10.10.10.59";
          username = "admin";
          password = "!env_var REOLINK_CAMERA_PASSWORD";
          port = 80;
          channel = 0;
          stream = "main";
        };
        "420" = {
          host = "10.10.10.60";
          username = "admin";
          password = "!env_var REOLINK_CAMERA_PASSWORD";
          port = 80;
          channel = 0;
          stream = "main";
        };
      };
    };
    extraComponents = [
      "mqtt"
      "zha"
      "stream"
      "ffmpeg"
      "radio_browser"
      "google_translate"
    ];
    extraPackages = py: with py; [
      getmac
      aiohomekit
      pyqrcode
      pypng
      pillow
      xmltodict
      radios
      gtts
    ];
  };
}
