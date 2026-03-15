# modules/nixos/host-options.nix
# Declarative options for host-level configuration
# This reduces hardcoded values and makes host configuration more consistent
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.host;
in
{
  options.host = {
    type = mkOption {
      type = types.enum [ "workstation" "server" "inference" "lxc" "gateway" ];
      description = "The type of host (affects default settings)";
      example = "workstation";
    };

    primaryUser = mkOption {
      type = types.str;
      default = "deepwatrcreatur";
      description = "Primary user account on this host";
    };

    gpu = {
      type = mkOption {
        type = types.enum [ "none" "amd" "nvidia" "intel" ];
        default = "none";
        description = "Type of GPU installed";
      };

      enableCuda = mkEnableOption "CUDA support for NVIDIA GPUs";

      enableRocm = mkEnableOption "ROCm support for AMD GPUs";
    };

    networking = {
      enableTailscale = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Tailscale VPN";
      };

      enableAvahi = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Avahi/mDNS";
      };
    };

    cache = {
      server = mkOption {
        type = types.str;
        default = "http://attic-cache:5001";
        description = "Binary cache server URL";
      };

      enableClient = mkOption {
        type = types.bool;
        default = true;
        description = "Enable binary cache client";
      };
    };

    desktop = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable desktop environment and related services";
      };

      environment = mkOption {
        type = types.enum [ "gnome" "kde" "cosmic" "none" ];
        default = "none";
        description = "Desktop environment to use";
      };

      enableSound = mkOption {
        type = types.bool;
        default = true;
        description = "Enable sound (PipeWire)";
      };

      enablePrinting = mkOption {
        type = types.bool;
        default = true;
        description = "Enable printing services";
      };
    };

    services = {
      enableSsh = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSH server";
      };

      enableDocker = mkEnableOption "Docker container runtime";

      enablePodman = mkEnableOption "Podman container runtime";
    };
  };

  config = mkMerge [
    # Base configuration for all hosts
    {
      # SSH server
      services.openssh.enable = cfg.services.enableSsh;

      # Tailscale
      services.tailscale.enable = cfg.networking.enableTailscale;

      # Avahi/mDNS
      services.avahi = mkIf cfg.networking.enableAvahi {
        enable = true;
        nssmdns4 = true;
        publish = {
          enable = true;
          addresses = true;
          domain = true;
          hinfo = true;
          userServices = true;
          workstation = true;
        };
      };
    }

    # Workstation-specific configuration
    (mkIf (cfg.type == "workstation") {
      host.desktop.enable = mkDefault true;
      host.services.enableDocker = mkDefault true;
    })

    # Server-specific configuration
    (mkIf (cfg.type == "server") {
      host.desktop.enable = mkDefault false;
      host.services.enableSsh = mkDefault true;
    })

    # Inference VM configuration
    (mkIf (cfg.type == "inference") {
      host.gpu.enableCuda = mkDefault (cfg.gpu.type == "nvidia");
      host.services.enableSsh = mkDefault true;

      # Higher resource limits for inference
      nix.settings = {
        max-jobs = mkDefault "auto";
        cores = mkDefault 0;
      };
    })

    # LXC container configuration
    (mkIf (cfg.type == "lxc") {
      # LXC-specific settings
      boot.isContainer = mkDefault true;
      host.desktop.enable = mkDefault false;
    })

    # Gateway/router configuration
    (mkIf (cfg.type == "gateway") {
      host.networking.enableTailscale = mkDefault true;
      host.services.enableSsh = mkDefault true;
    })

    # GPU configuration
    (mkIf (cfg.gpu.type == "nvidia") {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = mkDefault false;
        open = mkDefault false;
        nvidiaSettings = mkDefault true;
      };
      hardware.graphics.enable = true;

      # CUDA support
      nixpkgs.config.cudaSupport = cfg.gpu.enableCuda;
    })

    (mkIf (cfg.gpu.type == "amd") {
      boot.kernelModules = [ "amdgpu" ];
      services.xserver.videoDrivers = [ "amdgpu" ];
      hardware.graphics = {
        enable = true;
        # RADV is now the default Vulkan driver for AMD, amdvlk was removed
        extraPackages = with pkgs; [
          rocmPackages.clr.icd
        ];
      };

      # ROCm support
      nixpkgs.config.rocmSupport = cfg.gpu.enableRocm;
    })

    # Desktop configuration
    (mkIf cfg.desktop.enable {
      # Sound
      services.pipewire = mkIf cfg.desktop.enableSound {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      # Printing
      services.printing.enable = cfg.desktop.enablePrinting;
    })

    # Container runtimes
    (mkIf cfg.services.enableDocker {
      virtualisation.docker.enable = true;
      users.users.${cfg.primaryUser}.extraGroups = [ "docker" ];
    })

    (mkIf cfg.services.enablePodman {
      virtualisation.podman.enable = true;
    })
  ];
}
