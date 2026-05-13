# 36 Vaglio 25.11 Landing Transition

Status: `in-progress`
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

- The committed `ssh-keys/agenix-machine-identities/vaglio.pub` was wrong and
  did not match the live host's key.
- Rekeying the affected `vaglio` secrets against the live machine identity
  removes the previous `agenix` decryption failure for:
  `roundtable-secret-key-base`, `openai-api-key`, `gemini-api-key`,
  `anthropic-api-key`, `deepseek-api-key`, `github-token`, `nix-ci-netrc`,
  `attic-client-token`, and `root-ssh-key`.
- After that correction, the activation no longer fails in `agenix`; it
  progresses to the later stop/handoff phase and still wedges there.
- The remaining failure now looks narrower:
  after stopping `dbus-broker`, `network-setup`, `resolvconf`, and
  `roundtable`, the host falls into an old live-system handoff path and a
  transient `nixos-rebuild-switch-to-configuration` unit exits with status
  `11`.
- Two legacy bootstrap password secrets
  (`user-password-root.age` and `user-password-deepwatrcreatur.age`) still
  cannot be rekeyed from the currently available workstation identities, but
  they were not part of the observed live Vaglio decrypt failure.
