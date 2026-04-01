{
  pkgs,
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

  # Open firewall for Govee Child Bridge
  networking.firewall.allowedTCPPorts = [ 42140 ];

  # Inject dependencies for plugins with native modules (SwitchBot, Bluetooth)
  systemd.services.homebridge.path = [ 
    pkgs.openssl 
    pkgs.python3
    pkgs.gcc
    pkgs.gnumake
  ];

  # homebridge-alexa needs unauthenticated accessory access
  # HOMEBRIDGE_CONFIG_UI_SUDO allows the UI to manage plugins correctly
  systemd.services.homebridge.environment = {
    UIX_INSECURE_MODE = "1";
    HOMEBRIDGE_CONFIG_UI_SUDO = "1";
  };
}
