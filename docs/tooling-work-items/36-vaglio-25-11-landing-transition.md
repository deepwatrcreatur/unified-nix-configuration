# 36 Vaglio 25.11 Landing Transition

Status: `done`
Suggested branch: `fix/vaglio-switch-hang`
Priority: `high`

## Goal

Land `vaglio` onto the repo's current `25.11` baseline without losing network
reachability during activation.

## Why

- `main` is intentionally pinned to `nixos-25.11`.
- The live `vaglio` LXC was still on `26.05.20260505.549bd84`.
- Direct `switch-to-configuration test/switch` from current `main` hung
  mid-activation after stopping `dbus-broker`, `roundtable`, and the old DHCP
  stack.
- The guest then lost IPv4 until `dhcpcd` was restarted from Proxmox.

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
