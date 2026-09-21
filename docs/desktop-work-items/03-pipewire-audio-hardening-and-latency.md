# 03 PipeWire Audio Hardening & Latency Tuning

Status: `ready`
Suggested branch: `feat/pipewire-hardening`
Priority: `high`

## Goal

Harden PipeWire configuration against sudden volume jumps from applications and tune latency/quantum settings.

## Why

1. **Volume Spikes**: PipeWire Pulse defaults to flat volumes unless explicitly disabled, allowing applications (browsers, music players, games) to force master system volume up to 100%.
2. **Predictable Latency**: Enforcing standard clock rates and fixed quantums ensures stable audio performance across desktop tasks.
3. **Ergonomic Mixer**: Having `wiremix` (ncurses terminal mixer for PipeWire) available provides quick CLI audio control even when GUI settings or applets are down.

## Scope

1. Update PipeWire configuration (in `modules/nixos/services/audio.nix` or the workstation audio module):
   - Add `extraConfig.pipewire-pulse."99-no-flat-volume"` with `"pulse.properties"."pulse.flat-volume" = false;`.
   - Add `extraConfig.pipewire."92-low-latency"` with `"context.properties" = { "default.clock.rate" = 48000; "default.clock.quantum" = 1024; };`.
2. Add `wiremix` package to `environment.systemPackages`.

## Validation

- `nix eval .#nixosConfigurations.phoenix.config.services.pipewire.extraConfig.pipewire-pulse."99-no-flat-volume"` evaluates with `pulse.flat-volume = false`.
- Evaluation of `phoenix` and `emerald` toplevel succeeds.
