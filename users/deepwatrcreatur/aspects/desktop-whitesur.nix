# users/deepwatrcreatur/aspects/desktop-whitesur.nix
# Reusable Home Manager desktop aspect:
# WhiteSur GUI styling, desktop apps, MIME associations, screenshots, and DeskFlow setup.
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../../modules/home-manager/gnome-cosmic-style.nix
  ];

  home.packages = with pkgs; [
    ffmpeg
    gitkraken
    deskflow
    megacmd
    obsidian
    obsidian-export
    omasnap
    flameshot
    rustdesk
    virt-viewer
    xhost # X11 host access control for DeskFlow
    karere # WhatsApp desktop client replacement for removed wasistlos
  ];

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  gtk.gtk4.theme = config.gtk.theme;

  programs.google-chrome = {
    enable = true;
  };

  # Set default applications
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/png" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/jpeg" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/gif" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/webp" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
    };
    associations.added = {
      "image/png" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/jpeg" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/gif" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
      "image/webp" = [ "org.gnome.gThumb.desktop" "satty.desktop" ];
    };
  };

  xdg.desktopEntries.satty = {
    name = "Satty";
    genericName = "Screenshot Annotation";
    exec = "satty -f %f";
    terminal = false;
    categories = [ "Utility" "Graphics" ];
    mimeType = [ "image/png" "image/jpeg" ];
    icon = "satty";
    type = "Application";
    settings = {
      NoDisplay = "false";
    };
  };

  home.file.".config/deskflow/deskflow.conf".text = ''
    clipboardSharing = true
  '';

  # X11 display setup for DeskFlow
  systemd.user.services.xhost-deskflow = {
    Unit = {
      Description = "X11 host access for DeskFlow";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.xhost}/bin/xhost +local:";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Deskflow server service (disabled in favor of RustDesk)
  systemd.user.services.deskflow = {
    Unit = {
      Description = "Deskflow Server";
      After = [
        "graphical-session.target"
        "xhost-deskflow.service"
      ];
      Wants = [
        "graphical-session.target"
        "xhost-deskflow.service"
      ];
    };
    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.deskflow}/bin/deskflow server --config ${config.home.homeDirectory}/.config/deskflow/deskflow.conf
      '';
      Restart = "on-failure";
      RestartSec = "5";
      Environment = [
        "DISPLAY=:0"
        "XAUTHORITY=${config.xdg.cacheHome}/.Xauthority"
      ];
    };
    Install = {
      # Disabled: WantedBy = [ "graphical-session.target" ];
    };
  };
}
