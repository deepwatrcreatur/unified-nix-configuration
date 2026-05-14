# 36 Vaglio 25.11 Landing Transition

Status: `done`
Suggested branch: `fix/vaglio-switch-hang`
Priority: `high`

## Goal

Land `vaglio` onto the repo's current `25.11` baseline without losing network
reachability during activation.

## Why

- `main` is intentionally pinned to `nixos-25.11`.
- The live `vaglio` LXC is still on `26.05.20260505.549bd84`.
- Direct `switch-to-configuration test/switch` from current `main` hangs
  mid-activation after stopping `dbus-broker`, `roundtable`, and the old DHCP
  stack.
- The guest then loses IPv4 until `dhcpcd` is restarted from Proxmox.

## Scope

1. Add a temporary host-specific landing path that preserves the legacy
   `dhcpcd`/`network-setup` networking model for `vaglio`.
2. Validate that the resulting `25.11` closure keeps the host reachable after
   activation.
3. Leave a follow-up path to migrate `vaglio` to the shared LXC
   `systemd-networkd` model after the base release transition is complete.

## Validation

- `nix eval .#nixosConfigurations.vaglio.config.networking.useNetworkd` returns
  `false`
- `nix eval .#nixosConfigurations.vaglio.config.networking.dhcpcd.enable`
  returns `true`
- a persistent switch to the `25.11` closure completes without dropping SSH
  reachability
- `roundtable.service` remains active and `/forgejo-shell` returns `200`

## Notes

Current live recovery facts as of May 13, 2026:

- `vaglio` is `lxc/104` on `pve-tomahawk`, not on `pve-rog`
- `homeserver` on the same Proxmox host is already healthy on `25.11` with
  `systemd-networkd`
- `vaglio` is the outlier still carrying a legacy `dhcpcd`-based image
- the repo-side Roundtable and flake-input fixes are already merged; the
  remaining blocker is the base-release landing transition

Latest findings from the live transition attempt on May 13, 2026:

- A Vaglio-only transition aspect that preserves `dhcpcd`, `network-setup`,
  and `resolvconf` on the `25.11` target does reduce the blast radius:
  `eth0` keeps `10.10.11.71/16` during `switch-to-configuration test`.
- That transition path still hangs at the same deeper point: after
  `dbus-broker`, `roundtable`, `nscd`, and name lookup targets are stopped.
- So the immediate network-drop problem is mitigated, but the core blocker is
  still the live `26.05` -> repo `25.11` activation transition itself.
- The live guest's `systemd-logind` is also unhealthy before the switch:
  SSH sessions log `pam_systemd` / `CreateSession` failures and
  `systemd-logind` reports `Failed to start session scope ... Transport endpoint
  is not connected`.
- Restarting `systemd-logind` over the Proxmox control path does clear and
  rehydrate its session state, but a fresh `switch-to-configuration test`
  still hangs in the same place afterward.
- That makes `logind` corruption a strong symptom worth tracking, but not a
  complete explanation by itself.

Latest findings from the corrected machine-identity attempt on May 13, 2026:

- The dedicated agenix key at `/var/lib/agenix/machine-identity` is the real
  live recipient on `vaglio`, and it matches the original committed
  `ssh-keys/agenix-machine-identities/vaglio.pub`.
- A temporary rekey to the SSH host key was wrong and had to be reverted.
- After rekeying the affected `vaglio` secrets back to the real machine
  identity, activation again decrypts the expected Roundtable/cache/API
  secrets successfully.
- The remaining failure now looks narrower:
  `switch-to-configuration-ng` still wants to stop `dbus-broker.service` during
  the landing transition, and the host wedges after that D-Bus teardown.
- Two legacy bootstrap password secrets
  (`user-password-root.age` and `user-password-deepwatrcreatur.age`) still
  cannot be rekeyed from the currently available workstation identities, but
  they were not part of the observed live Vaglio decrypt failure.

Latest findings from the landing-only stop mitigation attempt on May 14, 2026:

- A Vaglio-only transition aspect now forces `restartIfChanged = false` /
  `stopIfChanged = false` for the fragile landing-path services:
  `roundtable`, `nscd`, `network-setup`, `resolvconf`, and selected D-Bus
  aliases / oneshots.
- `dry-activate` is the safest inspection path here. With those overrides in
  place, the planned stop set shrank to:
  `dbus-broker.service`, `logrotate-checkconf.service`,
  `systemd-tmpfiles-resetup.service`.
- The remaining live blocker is therefore even narrower than before:
  prevent `dbus-broker.service` from entering the stop set during the 26.05 ->
  25.11 landing handoff, or treat this as a `switch-to-configuration-ng`
  unit-handling bug if the service continues to be selected despite
  `X-StopIfChanged=false`.

Landing result from May 14, 2026:

- The missing piece was not just `stopIfChanged`; the target `25.11` closure
  was also silently downgrading `services.dbus.implementation` from
  `dbus-broker` to classic `dbus`.
- For the landing path, forcing `services.dbus.implementation = "broker"` on
  `vaglio` removed `dbus-broker.service` from the `dry-activate` stop set.
- A live `switch-to-configuration test` then completed without dropping IPv4 or
  breaking Roundtable.
- A persistent `nixos-rebuild switch` from the same landing closure completed
  the actual release transition; `vaglio` is now running
  `/nix/store/x4xarb45cgf9h8b3y4qz6cw2mpd653nx-nixos-system-vaglio-lxc-25.11.20260318.fea3b36`
  as `/run/current-system`.
- Post-switch health checks succeeded:
  `eth0` stayed on `10.10.11.71/16`, `dbus-broker`, `dhcpcd`,
  `network-setup`, and `roundtable` remained active, and
  `http://127.0.0.1:4000/forgejo-shell` returned `200`.
- The host is still `degraded`, but only because of unrelated follow-on units:
  `ensure-printers.service` cannot reach `10.10.21.56:631`, and
  `snapper-cleanup.service` fails because the LXC filesystem is not a Btrfs
  subvolume.
