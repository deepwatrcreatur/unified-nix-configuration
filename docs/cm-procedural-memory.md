# Cross-Agent Procedural Memory (CM)

This repo now adopts a **lightweight, provider-agnostic procedural memory
layer** alongside its existing documentation and agent tooling.

The goal is to capture small, repeatable procedures that multiple tools
(Claude, Copilot, Gemini, shell users) can apply, without tying them to a
vendor-specific memory system.

## Relationship to Existing Memory

This CM layer **does not replace**:

- `AGENTS.md` and `CLAUDE.md` (high-level instructions and guardrails)
- queue docs and work items (router/tooling task backlogs)
- handoff plans and design docs

Instead, CM focuses on concrete, step-by-step recipes that:

- are reused across sessions and agents
- are stable enough to document once and keep in sync
- are easy to find with normal search tools (ripgrep, `cass-session-search`)

## Where Procedures Live

Procedural memories live in this file for now, grouped by topic.

Agents should prefer **updating this doc** (or adding new sections) when
promoting a repeated ad hoc workflow into a reusable procedure.

Search entry points:

- `cass-session-search` for discovering prior sessions where a workflow was
  used or refined
- `rg` / `sg` over `docs/` (including this file) for the durable procedure

## When to Use CM vs Docs

Use **CM procedures in this file** when:

- you have a short, repeatable workflow with well-defined steps
- the steps are mostly mechanical (commands, flags, file paths)
- multiple agents or humans are likely to repeat it

Use **long-form docs** (`AGENTS.md`, design docs, handoff plans) when:

- you need background, rationale, or tradeoffs
- the work spans multiple branches/PRs or repos
- the workflow is still experimental or unstable

## Seed Procedures

### Remote rebuild + tmux pattern

Goal: run long Nix rebuilds or tests on a remote host without losing state
when the SSH session drops.

Steps (example for host `inference1`):

1. Create or attach to a named tmux session on the remote host:
   ```bash
   ssh inference1 "tmux new-session -d -s inference-test || tmux attach -t inference-test"
   ```
2. Start a long-running command in a dedicated tmux window:
   ```bash
   ssh -t inference1 "tmux new-window -t inference-test -n rebuild && \
   tmux send-keys -t inference-test:rebuild 'cd ~/flakes/unified-nix-configuration' Enter && \
   tmux send-keys -t inference-test:rebuild '/run/wrappers/bin/sudo nixos-rebuild test --flake .#inference1' Enter"
   ```
3. To monitor progress later:
   ```bash
   ssh -t inference1 "tmux attach -t inference-test"
   ```
4. When finished and no longer needed, clean up:
   ```bash
   ssh inference1 "tmux kill-session -t inference-test || true"
   ```

### Agenix secret editing (system/user)

Goal: edit an existing agenix-managed secret or create a new one safely.

1. Identify or add the secret definition in `secrets.nix` with the right
   `publicKeys`.
2. Use the `agenix-edit` helper (preferred):
   ```bash
   agenix-edit secrets-agenix/my-secret.age
   ```
   This runs the compatible `ryantm/agenix` CLI against the repo's
   `secrets.nix`.
3. For user-level secrets provisioned via `agenix-user-secrets`, ensure the
   relevant Home Manager module references the decrypted path under
   `~/.local/share/agenix-user-secrets/`.
4. Rebuild and verify the secret is available at the expected runtime path
   (e.g., `/run/agenix/my-secret` or the user secret path).

### fnox-backed command usage

Goal: use secrets via `fnox` without exporting long-lived tokens in shells.

1. Ensure `programs.fnox.enable = true` in the relevant Home Manager config.
2. Define or confirm `programs.fnox.seedSecretSources` mappings for the
   desired env vars (e.g., `GITHUB_TOKEN`, `ANTHROPIC_API_KEY`).
3. Prefer wrapper commands where available:
   - `gh` (aliased to `gh-fnox`)
   - `claude-code` (aliased to `claude-code-fnox`)
   - `opencode` (aliased to `opencode-zai`)
4. When a wrapper runs, it will:
   - respect existing env vars if they already contain sane values
   - otherwise fetch secrets via `fnox` from agenix-backed files
5. Avoid manually exporting provider API keys in shells; rely on fnox +
   agenix instead.

### Worktree / branch hygiene for agents

Goal: keep agent work isolated and recoverable when multiple branches are
active.

1. Prefer `wt` (worktrunk) over raw `git worktree` for new work:
   ```bash
   wt list
   wt switch -c feat/my-change
   ```
2. Within a worktree, keep **one work item per branch** and avoid mixing
   unrelated refactors.
3. Use queue docs (`docs/tooling-work-items/`, `docs/router-work-items/`) to
   claim ownership: set `Status: in-progress` when starting and `done` when
   merged.
4. When a branch is merged and no longer needed, clean up its worktree
   via `wt remove`.

## Future Extensions

If this CM layer proves useful, future work might include:

- adding a small index or tag format within this file
- wiring higher-level tools (Flywheel/CM) to read from and write to this
  doc in a structured way
- extracting especially stable procedures into dedicated, shorter files
  under a `docs/procedures/` tree.
