{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../../default.nix
    ./nh.nix
    ./distrobox.nix

    ../../../../modules/home-manager
    ../../../../modules/home-manager/ghostty
    ../../../../modules/home-manager/gpg-agent-cross-de.nix
    ../../../../modules/home-manager/zed.nix
    ../../../../modules/home-manager/cosmic-settings.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  # WhiteSur theming for MATE
  whitesur = {
    enable = true;
    gtk.enable = true;
  };

  # Automatically back up clobbered config files by allowing overwrites
  xdg.configFile."gtk-4.0/gtk.css".force = true;

  programs.distrobox.fedora.enable = true;

  home.packages = with pkgs; [
    bitwarden-desktop
    ffmpeg
    gitkraken
    deskflow
    libsecret
    megacmd
    nomachine-client
    obsidian
    obsidian-export
    rustdesk
    virt-viewer
  ];

  programs.firefox = {
    enable = true;
  };

  programs.google-chrome = {
    enable = true;
  };

  home.file.".config/deskflow/deskflow.conf".text = ''
    clipboardSharing = true
  '';

  # X11 display setup for DeskFlow (disabled)
  # systemd.user.services.xhost-deskflow = {
  #   Unit = {
  #     Description = "X11 host access for DeskFlow";
  #     After = [ "graphical-session.target" ];
  #     PartOf = [ "graphical-session.target" ];
  #   };
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.xorg.xhost}/bin/xhost +local:";
  #     RemainAfterExit = true;
  #   };
  #   Install = {
  #     WantedBy = [ "graphical-session.target" ];
  #   };
  # };

  # Deskflow server service (disabled to prevent autostart)
  # Start manually with: systemctl --user start deskflow
  # systemd.user.services.deskflow = {
  #   Unit = {
  #     Description = "Deskflow Server";
  #     After = [
  #       "graphical-session.target"
  #       "xhost-deskflow.service"
  #     ];
  #     Wants = [
  #       "graphical-session.target"
  #       "xhost-deskflow.service"
  #     ];
  #   };
  #   Service = {
  #     Type = "simple";
  #     ExecStart = ''
  #       ${pkgs.deskflow}/bin/deskflow server --config ${config.home.homeDirectory}/.config/deskflow/deskflow.conf
  #     '';
  #     Restart = "on-failure";
  #     RestartSec = "5";
  #     Environment = [
  #       "DISPLAY=:0"
  #       "XAUTHORITY=${config.xdg.cacheHome}/.Xauthority"
  #     ];
  #   };
  #   Install = {};
  # };

  home.stateVersion = "24.11";
}
