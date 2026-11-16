# Agent Tooling in This Repo

## Installed tools

Installed across hosts (or intended to be):

- `rg`, `fd`, `sg` (ast-grep, see [ast-grep.md](ast-grep.md)), `jq`, `just`
- `nh`, `nom`, `nvd`, `nix-tree` for Nix inspection
- `opencode`, `claude-code`, `gemini-cli`, `droid` (host-dependent)
- `cass-session-search`: search across local agent sessions
  ([docs/cass-session-search.md](../docs/cass-session-search.md))
- `beads-rust`: task graph CLI (`br` may be the Homebrew viewer on some hosts;
  see [docs/beads-migration-plan.md](../docs/beads-migration-plan.md))

Procedural memory: [docs/cm-procedural-memory.md](../docs/cm-procedural-memory.md).
Agent Mail is not adopted: [docs/agent-mail-workflow-fit.md](../docs/agent-mail-workflow-fit.md).

## Claude Code authentication

- Preferred command: `claude-code` (aliased to a `claude-code-fnox` wrapper
  when available).
- Auth is via `ANTHROPIC_API_KEY`, sourced by `fnox` from
  `~/.local/share/agenix-user-secrets/anthropic-api-key` or
  `/run/agenix/anthropic-api-key`. Operators provision it via
  agenix-user-secrets; agents should not export long-lived keys by hand.
- To bypass the alias for debugging: `command claude-code`.
- Other tools: [docs/tooling-managed-auth.md](../docs/tooling-managed-auth.md).

## Destructive command guard (`agent-guard`)

Home Manager installs `agent-guard` as a Claude Code `PreToolUse` hook on
`Bash` (and a Gemini CLI `BeforeTool` hook when enabled). It parses each
shell command, including `ssh host '...'`, `bash -c`, `sudo`, `xargs` and
`pct exec` wrappers, and:

- **asks for confirmation** before commands that destroy data or rewrite
  shared history: recursive `rm` outside `/tmp` and build artifacts,
  `find -delete`, force or deleting `git push`, `git reset --hard`,
  `git clean -f`, `git branch -D`, `git stash drop/clear`, disk tools
  (`mkfs`, `dd of=/dev/…`, `wipefs`, `sgdisk --zap-all`), `zfs`/`zpool
  destroy`, btrfs subvolume deletes, `qm`/`pct destroy`, container volume or
  system prunes, `kubectl delete`, `gh repo delete`, `gh api -X DELETE`, SQL
  `DROP`/`TRUNCATE`/unbounded `DELETE`, and `nix-collect-garbage -d`;
- **refuses** recursive deletes of `/`, `$HOME` and system directories such
  as `/nix` and `/etc`.

Gemini CLI has no confirmation path, so it blocks instead. Codex is not
covered. Check a command by hand with `agent-guard check '<command>'`. Skip it
for one session with `AGENT_GUARD_SKIP=1`; disable it for a host with
`programs.agent-guards.enable = false`. Policy: `scripts/agent-guard.py`;
cases: `tests/agent-guard-test.py` (the `agent-guard-policy` flake check).

## Web browsing

Use whatever browser or fetch tooling the agent environment provides. Do not
assume a specific browser automation stack. Prefer local files or direct URL
fetches over GUI browsing.
