# Managed Tooling Authentication

This document describes the repo-managed authentication paths for CLI tools and
agents in this infrastructure.

## Policy

Tools should prefer managed credential paths over ad hoc ambient shell state
(like manually exported `GH_TOKEN` or `API_KEY`). The repo provides three
primary integration patterns:

1.  **Managed Wrappers (`fnox`):** Commands like `gh`, `bw`, and `droid` are
    wrapped to automatically source secrets from `fnox` (and thus `agenix` or
    `sops`) before execution.
2.  **Standardized File Paths:** Tools that use structured configuration (like
    JSON/YAML) rely on standardized file paths provisioned by `agenix` or SOPS.
3.  **Bootstrap Environment:** `fnox` can be used to seed local state for tools
    that manage their own persistent sessions.

## Tool Integrations

### Gemini CLI (`gemini`, `gemini-cli`)

- **Integration Pattern:** Standardized File Path + Bootstrap seeding.
- **Credential Path:** `~/.gemini/oauth_creds.json`
- **Management:**
    - On workstations, this file is automatically provisioned by `agenix-user-secrets`.
    - On other hosts, it can be seeded using `fnox seed SEED_GEMINI_OAUTH > ~/.gemini/oauth_creds.json`.
- **Precedence:** `gemini-cli` reads the OAuth JSON file directly. No environment
  variable wrapper is currently used because the tool relies on a persistent
  OAuth session refresh token rather than a single static API key.

### Claude Code (`claude`)

- **Integration Pattern:** Bootstrap seeding.
- **Credential Path:** `~/.claude/config.json`
- **Management:**
    - Currently session-based. Use `fnox seed SEED_CLAUDE_CONFIG > ~/.claude/config.json` to bootstrap a known session from another host.
- **Precedence:** `claude-code` reads its local configuration file. No wrapper is
  used because the tool manages its own complex session state and local SQLite
  history.

### GitHub CLI (`gh`)

- **Integration Pattern:** Managed Wrapper (`gh-fnox`).
- **Secret Source:** `fnox get GITHUB_TOKEN`
- **Fallback:** `~/.local/share/agenix-user-secrets/github-token`
- **Management:** Automatically wired via the `gh-fnox` package in the
  coding-agent set.

### Bitwarden CLI (`bw`)

- **Integration Pattern:** Managed Wrapper (`bw-fnox`).
- **Secret Source:** `fnox get BW_SESSION` (managed via SOPS fallback).
- **Management:** Automatically wired via the `bw-fnox` package.

## Debugging

To bypass repo-managed authentication and run a "raw" command:

- For wrapped tools: Use the absolute path to the unwrapped binary (e.g.,
  `/nix/store/...-gh/bin/gh`) or use `rtk proxy <cmd>` if applicable.
- For file-based tools: Temporarily rename the managed file in `~/.gemini/` or
  override the relevant environment variables.
