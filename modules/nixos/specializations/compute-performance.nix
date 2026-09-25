# modules/nixos/specializations/compute-performance.nix
# Compute and performance bootloader specialization module.
# Optimizes CPU scaling governors, transparent hugepages, swappiness, PCIe link states,
# and systemd resource slice allocations for intensive compilation and local AI/LLM inference workloads.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myModules.specializations.computePerformance;
in
{
  options.myModules.specializations.computePerformance = {
    enable = lib.mkEnableOption "compute-performance specialization";
  };

  config = lib.mkIf cfg.enable {
    specialisation.compute-performance.configuration =
      { options, ... }:
      {
        system.nixos.tags = [ "compute-perf" ];

        # ---------------------------------------------------------
        # 1. 🚀 CPU FREQUENCY & GOVERNOR LOCK
        # ---------------------------------------------------------
        powerManagement.cpuFreqGovernor = lib.mkForce "performance";

        # ---------------------------------------------------------
        # 2. 🧠 MEMORY & TRANSPARENT HUGEPAGES TUNING
        # ---------------------------------------------------------
        boot.kernelParams = [
          "transparent_hugepage=always"
          "pcie_aspm=off"
        ];

        boot.kernel.sysctl = {
          # Reduce swap aggressiveness for high-memory compute
          "vm.swappiness" = 10;
          # Enhance memory mapping for high-context LLMs and large compilation units
          "vm.max_map_count" = 1048576;
          # Increase maximum open file descriptors
          "fs.file-max" = 2097152;
          # Aggressive page cache dirty flushing
          "vm.dirty_background_ratio" = 5;
          "vm.dirty_ratio" = 10;
        };

        # ---------------------------------------------------------
        # 3. ⚖️ SYSTEMD SLICE RESOURCE WEIGHTS & LIMITS
        # ---------------------------------------------------------
        systemd.extraConfig = ''
          DefaultLimitNOFILE=1048576
          DefaultLimitMEMLOCK=infinity
        '';

        systemd.user.extraConfig = ''
          DefaultLimitNOFILE=1048576
          DefaultLimitMEMLOCK=infinity
        '';

        systemd.slices.system.sliceConfig = {
          CPUWeight = 1000;
        };

        # High-performance CLI monitoring tools
        environment.systemPackages = with pkgs; [
          btop
          nvtopPackages.amd
          pciutils
        ];
      };
  };
}
