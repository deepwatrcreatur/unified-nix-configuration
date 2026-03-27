# Operations Notes

Operational notes that matter for rebuild workflows and host safety.

## LXC Safety

- Do not locally switch the `attic-cache` guest from `workstation`.
  `attic-cache` is a Proxmox LXC guest, and running a local `nixos-rebuild test` or
  `switch` for `.#attic-cache` on `workstation` can disrupt the desktop session.

## attic-cache Workflow

Preferred workflow:

```bash
ssh attic-cache
cd ~/flakes/unified-nix-configuration
git pull --ff-only
nixos-rebuild switch --flake .#attic-cache
```

Alternative workflow from another machine:

```bash
cd ~/flakes/unified-nix-configuration
just remote-test attic-cache
just remote-switch attic-cache
```

## Remote Rebuilds

For remote-only targets such as LXC guests:

- prefer `just remote-test <host>` before `just remote-switch <host>`
- use `--target-host` based rebuilds instead of switching the target locally

## Proxmox Home Manager Leaves

Proxmox root Home Manager outputs follow the leaf naming convention:

- host: `pve-tomahawk`
- home output: `pve-tomahawk-root`

The generic update path on a Proxmox node is:

```bash
home-manager switch --flake .#$(hostname)-root
```

## Git / Agent Notes

- Agents should commit without GPG signing to avoid pinentry failures.
- Prefer temporary worktrees or `wt` for parallel refactors rather than editing the same checkout concurrently.
