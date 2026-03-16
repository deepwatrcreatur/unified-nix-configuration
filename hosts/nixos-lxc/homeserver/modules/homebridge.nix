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
}
