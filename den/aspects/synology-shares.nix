# den/aspects/synology-shares.nix
# Resilient SMB automounts for Synology DSM shares (/cloud, /storage)
# Provides clean UID/GID mapping for deepwatrcreatur, fast failure on VM downtime,
# and declarative CIFS client tools.
{
  primaryUser ? "deepwatrcreatur",
  synologyHost ? "10.10.11.88",
  ...
}:
{ lib, pkgs, config, ... }:
let
  credsSecretFile = ../../secrets-agenix/synology-smb-credentials.age;
  hasAgenixSecret = builtins.pathExists credsSecretFile;

  credentialsPath =
    if hasAgenixSecret && (config ? age.secrets."synology-smb-credentials")
    then config.age.secrets."synology-smb-credentials".path
    else "/etc/synology-smb-credentials";

  mkShareMount = shareName: {
    device = "//${synologyHost}/${shareName}";
    fsType = "cifs";
    options = [
      # systemd automount & network dependency
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "_netdev"
      "soft"

      # Client permission mapping
      "uid=${primaryUser}"
      "gid=users"
      "forceuid"
      "forcegid"
      "file_mode=0770"
      "dir_mode=0770"

      # Authentication
      "credentials=${credentialsPath}"
    ];
  };
in
{
  # CIFS kernel mount helper and userland tools
  environment.systemPackages = with pkgs; [
    cifs-utils
    samba
  ];

  # Decrypt credentials via agenix if the .age file is present
  age.secrets = lib.mkIf hasAgenixSecret {
    "synology-smb-credentials" = {
      file = credsSecretFile;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  # Declarative mount points with systemd automount triggers
  fileSystems."/cloud" = mkShareMount "cloud";
  fileSystems."/storage" = mkShareMount "storage";

  # Ensure base mountpoint directories exist with proper permissions before mounting
  systemd.tmpfiles.rules = [
    "d /cloud 0775 ${primaryUser} users -"
    "d /storage 0775 ${primaryUser} users -"
  ];
}
