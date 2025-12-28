# modules/home-manager/gpu-monitoring.nix - GPU monitoring tools and aliases
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Define GPU monitoring shell aliases for reuse across shells
  shellAliases = {
    "gpu-status" = "nvidia-smi";
    "gpu-top" = "nvitop";
    "gpu-watch" = "watch -n 1 nvidia-smi";
    "gpu-temp" = "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits";
    "gpu-mem" = "nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits";
    "gpu-util" = "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits";
    "inference-monitor" = "nvitop";
  };

  # Create nushell functions for complex GPU monitoring operations
  nushellFunctions = ''
    # Enhanced GPU status with nushell formatting
    def gpu-info [] {
      nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu,temperature.gpu --format=csv,noheader,nounits
      | lines
      | parse "{name}, {mem_used}, {mem_total}, {util}, {temp}"
      | update mem_used { |row| $row.mem_used | into int }
      | update mem_total { |row| $row.mem_total | into int }
      | update util { |row| $row.util | into int }
      | update temp { |row| $row.temp | into int }
    }

    # Monitor GPU processes with nushell formatting
    def gpu-processes [] {
      nvidia-smi --query-compute-apps=pid,process_name,gpu_uuid,used_memory --format=csv,noheader,nounits
      | lines
      | where $it != ""
      | parse "{pid}, {name}, {gpu}, {memory}"
      | update pid { |row| $row.pid | into int }
      | update memory { |row| $row.memory | into int }
    }
  '';

  nushellAliases =
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "alias ${name} = ^${value}") shellAliases
    )
    + "\n\n"
    + nushellFunctions;
in
{
  config = {
    # GPU monitoring packages
    home.packages = with pkgs; [
      nvitop # Modern GPU monitoring tool
    ];

    # Shell aliases that merge with existing configs from other modules
    programs.bash.shellAliases = lib.mkMerge [ shellAliases ];
    programs.zsh.shellAliases = lib.mkMerge [ shellAliases ];
    programs.fish.shellAliases = lib.mkMerge [ shellAliases ];

    # Nushell configuration with enhanced GPU functions
    programs.nushell.extraConfig = lib.mkAfter ''
      ${nushellAliases}
    '';
  };
}