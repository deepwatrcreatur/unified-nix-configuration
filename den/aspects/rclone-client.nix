{ ... }:
{ lib, ... }:
let
  rcloneConfFile = ../../secrets-agenix/rclone-conf.age;
in
{
  age.secrets."rclone-conf" = lib.mkIf (builtins.pathExists rcloneConfFile) {
    file = rcloneConfFile;
    path = "/run/secrets/rclone-conf";
    owner = "deepwatrcreatur";
    mode = "0600";
  };
}
