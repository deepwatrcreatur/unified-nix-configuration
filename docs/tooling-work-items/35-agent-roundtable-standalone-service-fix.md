# 35 Agent-Roundtable Standalone Service Fix

Status: `done`
Suggested branch: `fix/agent-roundtable-standalone-service`
Priority: `high`

## Goal

Fix the standalone `agent-roundtable` `#vaglio` profile so its
`roundtable.service` starts cleanly on a fresh host without any runtime-only
systemd overrides.

## Why

- `vaglio` now exists as a real Proxmox LXC guest and can host the demo stack.
- The standalone profile switches successfully, but the service implementation
  has two runtime bugs:
  - the generated start script assumes `CREDENTIALS_DIRECTORY` is always set
  - the packaged `roundtable-web` wrapper runs Mix from a read-only
    `/nix/store` source tree, causing Hex dependency setup to fail with
    `{:error, :erofs}`
- A temporary runtime override on `vaglio` works around this by running from
  `/root/flakes/agent-roundtable/roundtable`, but that fix disappears on reboot.

## Scope

1. Patch the standalone service/startup logic in the `agent-roundtable` repo.
2. Make the service safe when no systemd credentials are configured.
3. Make the runtime path use a writable project directory or otherwise avoid
   Mix writes into `/nix/store`.
4. Rebuild `vaglio` without the runtime override and confirm the service starts
   cleanly.

## Non-Goals

- Roundtable secret rekeying in this repo
- Reattaching the inventory-backed `homeserver-roundtable` aspect
- Forgejo-shell UI work

## Validation

- `nixos-rebuild switch --flake .#vaglio` in the `agent-roundtable` repo
  produces a working `roundtable.service`
- no `/run/systemd/system/roundtable.service.d/local-dev-override.conf` is
  required
- `systemctl status roundtable` is `active (running)`
- `curl -I http://127.0.0.1:4000` returns `200 OK`

## Notes

Completed on May 13, 2026 via `agent-roundtable` PR #85.

That upstream fix:
- made the start path tolerate a missing `CREDENTIALS_DIRECTORY`
- moved the Mix runtime into writable XDG state instead of the read-only store

The standalone service bug is no longer the blocker for `vaglio`. The
remaining blocker is landing the host cleanly onto the repo's current `25.11`
baseline without hanging during activation.
