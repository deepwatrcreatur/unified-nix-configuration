{ ... }:
{ lib, pkgs, ... }:
let
  rcloneConfFile = ../../secrets-agenix/rclone-conf.age;
in
{
  environment.systemPackages = [ pkgs.rclone ];

  age.secrets."rclone-conf" = lib.mkIf (builtins.pathExists rcloneConfFile) {
    file = rcloneConfFile;
    path = "/run/secrets/rclone-conf";
    owner = "deepwatrcreatur";
    mode = "0600";
  };

  systemd.tmpfiles.rules = [
    "d /root/.config/rclone 0700 root root -"
    "L+ /root/.config/rclone/rclone.conf - - - - /run/secrets/rclone-conf"
  ];
}
