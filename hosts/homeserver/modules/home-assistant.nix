{
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

