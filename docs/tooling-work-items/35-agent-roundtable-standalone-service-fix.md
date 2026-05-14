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

On May 10, 2026, `vaglio` was made live with a runtime-only override that:
- cleared the `CREDENTIALS_DIRECTORY` assumption
- replaced `ExecStart` with a writable-checkout Mix launch

That proved the host and app can run, but the proper fix belongs upstream in
`/home/deepwatrcreatur/flakes/agent-roundtable`.

Validation notes from May 13, 2026:

- The standalone service was rebuilt on `vaglio` from the local
  `agent-roundtable` checkout.
- `roundtable.service` is `active (running)` without
  `/run/systemd/system/roundtable.service.d/local-dev-override.conf`.
- `curl -I http://127.0.0.1:4000` returns `HTTP/1.1 200 OK`.
- `nixos-rebuild switch --flake .#vaglio` reported an unrelated LXC mount
  failure for `sys-kernel-debug.mount`, but the Roundtable service validation
  itself succeeded.
