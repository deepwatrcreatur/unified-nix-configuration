# unified-nix-configuration

Unified flake for NixOS, nix-darwin, and Home Manager configurations across the machines in this environment.

## Layout

```text
.
├── flake.nix
├── flake.lock
├── lib/flake/            # Flake builder and output-loading logic
├── den/                  # den-style inventory, aspects, and host glue
├── outputs/              # Output loaders and special-case outputs
├── hosts/                # Host-specific NixOS and Darwin configuration trees
├── modules/              # Shared NixOS, Home Manager, Darwin, and helper modules
├── users/                # User-level Home Manager configuration and host overrides
├── overlays/             # Overlay definitions imported by the flake library
├── pkgs/                 # Local packages
├── experiments/den-lxc/  # Den-style inventory/aspect prototype layer
├── secrets-agenix/       # Encrypted agenix secrets
├── ansible/              # Operational playbooks
└── docs/                 # Runbooks and migration notes
```

## Outputs

Regular outputs are generated from inventory instead of one wrapper file per host.

- `nixosConfigurations.<host>`: standard NixOS hosts
- `darwinConfigurations.<host>`: nix-darwin hosts
- `homeConfigurations.<name>`: standalone Home Manager targets such as `proxmox-root`
- `nixosConfigurations.*-den`: experimental den-style prototype outputs under `experiments/den-lxc`

`outputs/nixos-lxc.nix` remains a special-case output file for the bootstrap LXC variants.

## Commands

Common local operations:

```bash
nix flake metadata
nix flake check
/run/wrappers/bin/sudo nixos-rebuild switch --flake .#<hostname>
home-manager switch --flake .#<home-output>
nh os switch -H <hostname> -f ~/flakes/unified-nix-configuration
nh home switch ~/flakes/unified-nix-configuration#<home-output>
```

Examples:

```bash
/run/wrappers/bin/sudo nixos-rebuild switch --flake .#workstation
/run/wrappers/bin/sudo nixos-rebuild switch --flake .#router
home-manager switch --flake .#proxmox-root
```

## GitHub Inputs

Public GitHub flake inputs use `github:` URLs rather than `git+ssh`.

This is intentional:

- host-local rebuilds are more reliable when Nix fetches public repos over authenticated HTTPS
- this repo already provisions GitHub tokens for Nix
- `git+ssh` should be reserved for genuinely private repositories

Relevant token plumbing lives in:

- `modules/common/nix-settings.nix`
- `modules/home-manager/common/nix-user-config.nix`
- `modules/home-manager/user-secrets.nix`
- `modules/nixos/common/nix-ci-netrc.nix`

## Worktrees

Use `worktrunk` (`wt`) for parallel agent work in separate git worktrees.

- Create or switch: `wt switch -c feat/my-change`
- List: `wt list`
- Remove: `wt remove`

## Notes

- Some operational repo clones on hosts may drift or become conflicted over time; rebuilding from a clean checkout is often safer than repairing in place.
- The den-style prototype is merged as an experiment and currently targets the LXC-style hosts first.
