# 05 Decouple Podman Container Stacks into Atomic Aspects

Status: `ready`
Suggested branch: `feat/aspect-atomic-containers`
Priority: `medium`

## Goal

Decompose the monolithic `den/aspects/podman-containers.nix` into atomic, single-service container aspects so that individual homelab services can be hosted, migrated, or scheduled independently across nodes.

## Why

In `den/aspects/podman-containers.nix`, eight distinct container services (`plex`, `paperless`, `home-assistant`, `nightscout`, `graylog`, `scrypted`, `librelinkup`, `netalertx`) are tightly coupled into a single aspect. All persistent directories, firewall rules, and container definitions are bundled together.

This creates architectural friction:
- Moving a service with GPU transcoding needs (e.g. `plex`) to an inference VM or bare-metal node requires dismantling the entire aspect.
- Workloads cannot be distributed or rebalanced across nodes in `den/inventory/hosts.nix`.
- A failure or misconfiguration in one stack affects the unified aspect.

## Scope

1. Decompose `den/aspects/podman-containers.nix` into discrete service aspects under `den/aspects/`:
   - `den/aspects/service-plex.nix`: Plex Media Server container, transcode volume, port `32400`.
   - `den/aspects/service-paperless.nix`: Paperless-ngx stack, documents/data directories.
   - `den/aspects/service-homeassistant.nix`: Home Assistant container, configuration directories.
   - `den/aspects/service-nightscout.nix`: Nightscout CGM container, port `11337`.
   - `den/aspects/service-graylog.nix`: Graylog logging stack and dependencies.
   - `den/aspects/service-scrypted.nix`: Scrypted video integration container.
   - `den/aspects/service-netalertx.nix`: NetAlertX network monitor.
   - `den/aspects/service-librelinkup.nix`: LibreLinkUp container.
2. Create a base `den/aspects/podman-base.nix` providing common Podman daemon runtime settings (`virtualisation.podman.enable = true;`, auto-prune, dockerCompat).
3. Register the new aspects in `den/aspects/default.nix`.
4. Update `den/inventory/hosts.nix` for the `podman` host leaf to compose `podman-base` along with the individual service aspects.

## Validation

- `nix build .#checks.x86_64-linux.inventory-consistency --no-link` passes.
- `nix eval .#nixosConfigurations.podman.config.system.build.toplevel.drvPath` evaluates to an identical or functionally equivalent derivation.
- Container services, firewall ports, and tmpfiles rules are preserved without omission.
