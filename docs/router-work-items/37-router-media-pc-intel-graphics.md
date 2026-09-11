# Router Media PC Intel Graphics & Display Enablement

Status: `ready`
Priority: `medium`
Branch: `feat/router-media-pc-intel-graphics`

## Goal

Enable the Intel integrated graphics driver (`i915`), VA-API hardware video
acceleration, and display output on the baremetal router so that the machine can
function as a home Media PC while retaining all routing and firewall
capabilities. In addition, ensure that headless GPU power optimization remains a
clean opt-in option in the `nix-router-optimized` flake rather than a forced
default.

## Context & Architecture

- **Hardware**: The baremetal router is an Intel Core i7-6700 with Intel HD
  Graphics 530 (Skylake GT2), equipped with HDMI/DisplayPort outputs.
- **Dual-Purpose Requirement**: The operator will connect displays and media
  services to the router machine to use it as a media PC.
- **Flake Optimization Alignment**: While blog posts on headless routers (such
  as Stark's N150 post) recommend blacklisting graphics drivers (`i915`) to
  reclaim a few hundred megabytes of RAM and eliminate DRM worker threads, this
  must **not** be enforced globally or enabled by default on dual-purpose media
  PC routers.
- In `nix-router-optimized`: The flake must expose an explicit, opt-in toggle
  (e.g. `services.router-optimizations.headless.enable = lib.mkEnableOption ...`)
  defaulting to `false`, allowing purely headless users to enable it without
  breaking media PC setups.

## Scope

### 1. In `unified-nix-configuration` (Host: `router`)
- In [`hosts/nixos/router/hardware-configuration.nix`](file:///home/deepwatrcreatur/flakes-worktrees/unified-nix-configuration/main/hosts/nixos/router/hardware-configuration.nix)
  and [`hosts/nixos/router/role.nix`](file:///home/deepwatrcreatur/flakes-worktrees/unified-nix-configuration/main/hosts/nixos/router/role.nix):
  - Ensure `boot.kernelModules = [ "kvm-intel" "i915" ]`.
  - Ensure `i915` is **not** blacklisted.
  - Enable hardware graphics acceleration:
    ```nix
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        libvdpau-va-gl
      ];
    };
    ```
  - Configure audio / sound support if needed for media playback.

### 2. In `nix-router-optimized` Flake
- In `modules/router-optimizations.nix`:
  - Define an opt-in headless optimization submodule:
    ```nix
    options.services.router-optimizations.headless = {
      enable = lib.mkEnableOption "headless router optimizations (power tuning and graphics module suppression)";
    };
    ```
  - When `headless.enable = true;`, apply power governor tuning and graphics
    module blacklisting (`boot.blacklistedKernelModules = [ "i915" "amdgpu" "nouveau" ]`).
  - When `headless.enable = false;` (default), leave display drivers and graphics
    subsystems fully enabled for media PC or interactive console usage.

## Non-Goals

- Degrading networking or packet forwarding performance when media playback is
  active.
- Running heavy desktop compositors if a lightweight media center / Kodi / mpv
  is sufficient.

## Validation

- `/dev/dri/card0` and `/dev/dri/renderD128` exist on the live router.
- `vainfo` or `intel_gpu_top` confirms Intel HD Graphics 530 acceleration is
  active.
- Display output delivers picture to connected monitor/TV.
- Flake evaluation verifies that `services.router-optimizations.headless.enable`
  defaults to `false`.
