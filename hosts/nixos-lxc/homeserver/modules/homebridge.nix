{
  ...
}:
{
  services.homebridge = {
    enable = true;
    openFirewall = true;

    settings = {
      bridge = {
        name = "Homelab Homebridge";
        username = "0E:10:11:69:00:01";
        pin = "173-29-451";
      };
    };

    uiSettings.port = 8581;
  };

  # homebridge-alexa needs unauthenticated accessory access, which Homebridge
  # enables through the UIX_INSECURE_MODE environment variable when using
  # homebridge-config-ui-x / hb-service.
  systemd.services.homebridge.environment.UIX_INSECURE_MODE = "1";
}
