{ config, lib, ... }:
let
  cfg = config.myModules.inferenceModels;
in {
  options.myModules.inferenceModels = {
    enable = lib.mkEnableOption "Shared inference model storage";

    type = lib.mkOption {
      type = lib.types.enum [ "cephfs" "virtiofs" "hostPath" ];
      default = "cephfs";
      description = ''Backend type for shared model storage.
        - cephfs: models on a CephFS mount
        - virtiofs: models passed from Proxmox host via virtiofs
        - hostPath: plain local/host-mounted path (no extra wiring)'';
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/srv/models";
      description = "Directory where models are available to inference services.";
    };

    ceph = {
      fsName = lib.mkOption {
        type = lib.types.str;
        default = "modelsfs";
        description = "CephFS filesystem name for models (when type = cephfs).";
      };

      monitors = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = [ "10.20.0.11" "10.20.0.12" "10.20.0.13" ];
        description = "List of Ceph monitor addresses for cephfs mounts.";
      };

      mountOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra mount options for CephFS.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      mp = cfg.mountPoint;
    in
    {
      # Ensure base directory exists; actual content may come from a mount.
      systemd.tmpfiles.rules = [
        "d ${mp} 0755 root root -"
        "d ${mp}/models 0755 root root -"
      ];

      # Only declare CephFS mount when requested; virtiofs/hostPath are provided by host.
      fileSystems = lib.mkIf (cfg.type == "cephfs") {
        "${mp}" = {
          fsType = "ceph";
          # Using kernel client form: mon1,mon2,mon3:/
          device = lib.concatStringsSep "," cfg.ceph.monitors + ":/";
          options = [
            "name=admin"  # TODO: make configurable; placeholder for now
            "_netdev"
          ] ++ cfg.ceph.mountOptions;
        };
      };
    }
  );
}
