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
    ../../../../modules/home-manager/just.nix
    ../../../../modules/home-manager/just-nixos.nix
    ../../../../modules/home-manager/gpg-cli.nix
    ../../../../modules/home-manager/zed.nix
    # Desktop session configuration (uncomment one):
    # ../../../../modules/home-manager/cinnamon.nix
    ../../../../modules/home-manager/gnome-whitesur.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  programs.distrobox.fedora.enable = true;

  home.packages = with pkgs; [
    bitwarden-desktop
    ffmpeg
    gitkraken
    deskflow
    mailspring
    megacmd
    obsidian
    obsidian-export
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

  # Deskflow server service
  systemd.user.services.deskflow = {
    Unit = {
      Description = "Deskflow Server";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.deskflow}/bin/deskflow server --config ${config.home.homeDirectory}/.config/deskflow/deskflow.conf
      '';
      Restart = "on-failure";
      RestartSec = "5";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  home.stateVersion = "24.11";
}
