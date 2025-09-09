{ config, lib, pkgs, ... }:

{
  # CephFS configuration
  environment.etc."ceph/ceph.conf".text = ''
    [global]
    mon_host = 10.10.11.55:6789
  '';
  
  environment.etc."ceph/ceph.keyring".text = ''
    AQBIfuZn15t6BhAACU50sq1eO62VEBzMXpq5HQ==
  '';

  # CephFS mount for models
  fileSystems."/models" = {
    device = "10.10.11.55:6789:/models";
    fsType = "ceph";
    options = [
      "name=admin"
      "secretfile=/etc/ceph/ceph.keyring"
      "_netdev"
      "noatime"
    ];
  };

  # Local storage mount for ollama data
  fileSystems."/ollama" = {
    device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";
    fsType = "ext4";
    options = [ "defaults" "rw" ];
  };

  # Add ceph client to system packages
  environment.systemPackages = with pkgs; [
    ceph-client
  ];
}