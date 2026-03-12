{
  config,
  pkgs,
  lib,
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
    ../../../../modules/home-manager/common/dmux.nix
  ];

  programs.dmux.enable = true;

  programs.distrobox.fedora.enable = true;

  home.packages = with pkgs; [
    inputs.nix-linuxbrew.packages.${pkgs.stdenv.hostPlatform.system}.brew-wrapper
    bitwarden-desktop
    ffmpeg
    gitkraken
    deskflow
    megacmd
    obsidian
    obsidian-export
    rustdesk
    virt-viewer
    xorg.xhost # X11 host access control for DeskFlow
    wasistlos # WhatsApp desktop client (was previously whatsapp-for-linux)
  ];

  programs.firefox = {
    enable = true;
  };

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

  # Allow dconf activation so COSMIC/GNOME settings (theme/wallpaper) apply.
  # If you see activation-time dconf errors again, we can gate this behind a
  # `graphical-session.target` user service instead.

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
      ExecStart = "${pkgs.xorg.xhost}/bin/xhost +local:";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Deskflow server service (disabled in favor of RustDesk)
  # Start manually with: systemctl --user start deskflow
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

  home.stateVersion = "24.11";
}
