{
  lib,
  ...
}:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = lib.mkDefault "/dev/disk/by-id/nvme-WDS500G3X0C-00SJG0_21107G804181";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };

          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };

    disk.spinning = {
      type = "disk";
      device = lib.mkDefault "/dev/disk/by-id/ata-ST9500325AS_S2W1JKQY";
      content = {
        type = "gpt";
        partitions = {
          logs = {
            label = "disk-logs-logs";
            size = "200G";
            content = {
              type = "filesystem";
              format = "ext4";
              # No mountpoint — router-log-storage service handles the mount.
              # Partition label is disk-logs-logs.
            };
          };

          images = {
            label = "disk-pxe-images-images";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              # Mounted from configuration.nix (/srv/pxe).
              # Partition label is disk-pxe-images-images.
            };
          };
        };
      };
    };
  };
}
