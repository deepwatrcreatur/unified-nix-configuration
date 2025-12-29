{
  config,
  lib,
  pkgs,
  ...
}:

{
  # CephFS configuration (disabled until ceph server is configured)
  # environment.etc."ceph/ceph.conf".text = ''
  #   [global]
  #   mon_host = 10.10.11.55:6789
  # '';
  #
  # environment.etc."ceph/ceph.keyring".text = ''
  #   AQBIfuZn15t6BhAACU50sq1eO62VEBzMXpq5HQ==
  # '';

  # CephFS mount for models (disabled until ceph server is configured)
  # fileSystems."/models" = {
  #   device = "10.10.11.55:6789:/models";
  #   fsType = "ceph";
  #   options = [
  #     "name=admin"
  #     "secretfile=/etc/ceph/ceph.keyring"
  #     "_netdev"
  #     "noatime"
  #   ];
  # };

  # Local storage mount for ollama data (drive-scsi1 doesn't exist on this VM)
  # Only drive-scsi0 exists, which is the main system disk
  # TODO: Add additional storage disk if needed for ollama data

  # Add ceph client to system packages
  environment.systemPackages = with pkgs; [
    ceph-client
  ];
}
