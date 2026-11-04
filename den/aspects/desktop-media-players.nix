# den/aspects/desktop-media-players.nix
# Default video player: mpv with the uosc interface and thumbfast seek previews.
# VLC is installed alongside it for disc menus and casting.
{
  primaryUser ? "deepwatrcreatur",
  ...
}:
{ lib, pkgs, ... }:
let
  mpvWithScripts = pkgs.mpv.override {
    scripts = with pkgs.mpvScripts; [
      uosc
      thumbfast
      mpris
    ];
  };

  videoMimeTypes = [
    "video/3gpp"
    "video/mp2t"
    "video/mp4"
    "video/mpeg"
    "video/ogg"
    "video/quicktime"
    "video/webm"
    "video/x-flv"
    "video/x-m4v"
    "video/x-matroska"
    "video/x-ms-wmv"
    "video/x-msvideo"
  ];
in
{
  environment.systemPackages = [
    # hiPrio: some hosts also get plain mpv from the workstation profile, and that
    # build has no controls once mpv.conf turns off the built-in OSC for uosc.
    (lib.hiPrio mpvWithScripts)
    pkgs.vlc
  ];

  xdg.mime.defaultApplications = lib.genAttrs videoMimeTypes (_: "mpv.desktop");

  home-manager.users.${primaryUser}.xdg.configFile."mpv/mpv.conf".text = ''
    # uosc replaces the built-in on-screen controller and seek bar.
    osc=no
    osd-bar=no

    hwdec=auto-safe
    save-position-on-quit=yes
    keep-open=yes
  '';
}
