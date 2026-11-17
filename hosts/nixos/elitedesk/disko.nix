# Disk layout for elitedesk.
#   main     240 GB T-FORCE SSD   -> OS (btrfs)
#   spinning 700 GB Hitachi HDD   -> router logs + PXE ISO images
#   big      10 TB WD Red Plus    -> /big (uses not decided yet)
# Labels on the spinning disk match router's, so router-log-storage and the
# /srv/pxe mount work unchanged when elitedesk takes over.
{ lib, ... }:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = lib.mkDefault "/dev/disk/by-id/ata-T-FORCE_240GB_TPBF2311070050100823";
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
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
              };
            };
          };
        };
      };
    };

    disk.spinning = {
      type = "disk";
      device = lib.mkDefault "/dev/disk/by-id/ata-Hitachi_HTS547575A9E384_J2140059DH9S1A";
      content = {
        type = "gpt";
        partitions = {
          logs = {
            label = "disk-logs-logs";
            size = "250G";
            content = {
              type = "filesystem";
              # WHY: XFS for many concurrent appenders (Prometheus TSDB,
              # Grafana, Technitium and Suricata logs) on a spinning disk, and
              # journal replay instead of fsck after power loss. Must match
              # services.router-log-storage.fsType in configuration.nix.
              format = "xfs";
              # No mountpoint: router-log-storage mounts it by label.
            };
          };

          images = {
            label = "disk-pxe-images-images";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              # Mounted at /srv/pxe from configuration.nix.
            };
          };
        };
      };
    };

    disk.big = {
      type = "disk";
      device = lib.mkDefault "/dev/disk/by-id/ata-WDC_WD101EFBX-68B0AN0_VCJ36KPP";
      content = {
        type = "gpt";
        partitions.big = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" "-L" "big" ];
            subvolumes."@big" = {
              mountpoint = "/big";
              # WHY: nofail so a dead data disk cannot stop the router booting.
              mountOptions = [ "compress=zstd" "noatime" "nofail" ];
            };
          };
        };
      };
    };
  };
}
