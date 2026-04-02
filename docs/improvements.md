# Improvements (updated 2026-03-28)

This document is the live backlog for `unified-nix-configuration`.  It is
intentionally actionable: each item describes what to do, what the blocker is
(if any), and what success looks like.  Update or replace it as items ship.

## Active threads — do not clobber

- **authentik-host bootstrap** — staged in the working tree (8 files).  Commit
  those files when the host is ready.  Everything else is safe to work on in
  parallel.

---

## Deferred

### A. Add machine-identity keys for inference1/2/3, phoenix, rustdesk

**Why it matters:** `machineRecipients` silently returns `[]` for any host that
has neither a `.pub` file in `ssh-keys/agenix-machine-identities/` nor a
legacy key in the `hosts` dict in `secrets.nix`.  This means those machines
cannot self-decrypt agenix secrets (attic-client-token, root-ssh-key, etc.).
The `inventory-consistency` check now surfaces these as a non-fatal notice.

**What to do:**
1. SSH into each host and read `/etc/ssh/ssh_host_ed25519_key.pub` (or run
   the `my.agenix.machineIdentity` bootstrap if that module is active).
2. Write the key to `ssh-keys/agenix-machine-identities/<hostname>.pub`.
3. Run `nix run github:ryantm/agenix -- -r` to rekey all secrets.
4. Verify `inventory-consistency` notice disappears.

**Hosts:** inference1, inference2, inference3, phoenix, rustdesk

---

## Working rules for agents

- Run `nix build .#checks.x86_64-linux.inventory-consistency` after every
  structural change.
- Commit without GPG signing: `git commit --no-gpg-sign`.
- Keep changes build-tested.  Prefer narrow commits by concern.
- Do not modify staged `authentik-host` files unless continuing that thread.
- Do not rekey secrets casually — recipients must be correct before rekeying.
