# Unified Nix Configuration: notes for coding agents

One flake that configures every machine: NixOS hosts (including the router
and homeserver), Proxmox LXC guests, macOS via nix-darwin, and Home Manager
users. Secrets use agenix.

New to the repo? Read [`agent-guides/START-HERE.md`](agent-guides/START-HERE.md),
then [`den/README.md`](den/README.md).

## Layout

- `den/inventory/`: the source of truth for exported hosts and homes
  (`hosts.nix`, `darwin.nix`, `homes.nix`, `bootstrap.nix`).
- `den/hosts/<host>/`: thin host leaves that compose aspects and add
  hardware or networking. `mode = "legacy"` hosts are still backed by
  `hosts/`.
- `den/aspects/`: reusable bundles (`lxc-core`, `attic-client`, ...).
- `modules/common/` (all hosts), `modules/nixos/`, `modules/nix-darwin/`
  (auto-imported only on Darwin), `modules/home-manager/`; `profiles/` for
  opinionated shared bundles.
- `users/<user>/` with per-host overrides in `users/<user>/hosts/<host>/`.
- `secrets-agenix/` with recipients in `secrets.nix`.
- `outputs/`: flake outputs (`den.nix`, `checks.nix`, ...);
  `lib/flake/helpers.nix`: system builders.

Put platform-specific settings in the platform directory, not behind
conditionals in `modules/common/`. A Darwin-only option such as
`nix.settings.max-open-files` breaks NixOS evaluation (`unknown setting`)
if it lands in a common module.

## Hosts and shells

- Run `hostname` first; you may be on emerald, homeserver or another host.
- NixOS: use `/run/wrappers/bin/sudo`, not plain `sudo` or
  `/run/current-system/sw/bin/sudo`.
  `/run/wrappers/bin/sudo nixos-rebuild switch --flake .#<host>`.
  Darwin: `darwin-rebuild switch --flake .#<host>`.
- Remote: `nixos-rebuild switch --flake .#<host> --target-host <host> --sudo`.
  Router specifics: [`docs/router-source-of-truth.md`](docs/router-source-of-truth.md).
- **Never rebuild `attic-cache` locally.** It is a Proxmox LXC guest; a local
  `nixos-rebuild test/switch --flake .#attic-cache` can kill the desktop
  session. SSH in, `git pull` in `~/flakes/unified-nix-configuration` and
  rebuild there, or use `--target-host attic-cache --sudo`.
- The interactive shell is Fish almost everywhere. Write automation in Bash:
  use `ssh-bash <host> -- ...` (or `ssh host "bash -c '...'"`) for remote
  commands. Avoid Nushell for automation.
- Long-running work: herdr on developer hosts, tmux on servers without it; see
  [`agent-guides/persistent-sessions.md`](agent-guides/persistent-sessions.md).

## Secrets

- Edit or create with `agenix-edit secrets-agenix/<name>.age` (runs
  `ryantm/agenix` against `secrets.nix`). Do not use `agenix-cli`; its config
  format is different. Do not add `agenix` to `home.packages` to edit secrets.
- New secret: add it to `secrets.nix` with its `publicKeys`, create it with
  `agenix-edit`, reference it via `config.age.secrets.<name>.path`.
- Without `agenix-edit`: get recipients with
  `nix eval --impure --expr '(import ./secrets.nix)."secrets-agenix/<name>.age".publicKeys'`
  and encrypt with `age -r ... -o secrets-agenix/<name>.age`.
- SOPS-nix remains only as a small compatibility layer in a few Home Manager
  modules.

## Validating

- Build or test before committing, and read all output: warnings, failed
  activation scripts and silent package failures count. "Build succeeded" is
  not "the fix works"; check the thing you meant to fix.
- Quick eval of a host:
  `nix eval .#nixosConfigurations.<host>.config.networking.hostName`.
- Flake checks: `module-loading-eval`, `inventory-consistency`,
  `agent-guard-policy` (`nix build .#checks.x86_64-linux.<name>`).
- Before every commit, check for conflict markers: `git diff --cached --check`
  (reports "leftover conflict marker"). For the whole tree:
  `grep -rnE '^(<<<<<<<|=======|>>>>>>>)( |$)' modules/ hosts/ users/ lib/ den/ --include='*.nix'`.
  The unanchored grep also matches `# =====` comment rulers.
- HTTP 401 from a binary cache is usually harmless: Nix falls back to public
  caches when a token is missing.

## Git

- Pull before pushing changes that affect remote hosts. Keep commits narrowly
  scoped (secrets refactor separate from desktop tweaks).
- Commits are SSH-signed by default. If signing prompts or fails in an agent
  session, run `./scripts/git-ssh-doctor.sh` before assuming SSH is broken;
  fall back to `git commit --no-gpg-sign` only when signing is unavailable.
- Shared checkout for sequential or read-only work; `wt` (worktrunk) worktrees
  for parallel agents or PR-sized work:
  [`agent-guides/checkout-strategies.md`](agent-guides/checkout-strategies.md),
  [`agent-guides/worktrunk.md`](agent-guides/worktrunk.md).

## Agent tooling

Tools, Claude Code auth, the `agent-guard` destructive-command hook, and web
browsing: [`agent-guides/tooling.md`](agent-guides/tooling.md). The guard
asks before destructive commands (`rm -r`, force pushes, disk tools,
`qm`/`pct destroy`, ...); check one with `agent-guard check '<command>'`.

<!-- nix-agent-guides:core BEGIN (v2). Synced from deepwatrcreatur/nix-agent-guides templates/agents-core.md by scripts/sync-agents-core.sh. Edit it there, not here. -->
## Shared conventions

Canonical, newest version:
https://raw.githubusercontent.com/deepwatrcreatur/nix-agent-guides/main/CONVENTIONS.md
If you can fetch it, read it before larger changes; where it differs from the
summary below, it is newer. This repo's own instructions above take
precedence over both.

Summary (offline fallback):

- **Comments explain why, not what.** Mark them `# WHY:`, `# GOTCHA:`,
  `# INVARIANT:`, `# SECURITY:`, `# UPSTREAM:` or `# TODO(#issue):`. One to
  three lines above the code they protect; longer reasoning goes in `docs/`
  with a pointer (`# WHY: docs/x.md#heading`). Never narrate the next line.
- **Before editing a file**, read its tags:
  `rg -n '# (WHY|GOTCHA|INVARIANT|SECURITY|UPSTREAM|TODO)' <file>`.
  Fix or delete any tag your change makes untrue.
- **Exported Nix functions** get RFC 145 doc comments (`/** ... */`).
- **Validate before committing:** the narrowest `nix build` first, then
  `nix flake check`; read all output. Run `bash -n`/`shellcheck` on shell
  generated from Nix. Exit code 0 is not proof the change worked.
- **Same change, same PR:** behaviour changes come with docs and a check.
- **Never commit secrets**, and do not deploy to or change live hosts unless
  asked.
<!-- nix-agent-guides:core END -->
