{ config, pkgs, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Cinnamon desktop environment.
  services.xserver.desktopManager.cinnamon.enable = true;

  # Cinnamon's panel can be configured to act as a dock, so no extra package
  # is needed. It also includes a workspace switcher with previews and
  # supports moving windows between workspaces with the mouse.

  # Application launcher - Ulauncher (similar to Spotlight/Alfred)
  # Launch with Ctrl+Space (configurable in Ulauncher preferences)
  environment.systemPackages = with pkgs; [
    ulauncher
  ];

  # Enable Ulauncher to start on login
  systemd.user.services.ulauncher = {
    description = "Ulauncher application launcher";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.ulauncher}/bin/ulauncher --hide-window";
      Restart = "on-failure";
    };
  };
}
