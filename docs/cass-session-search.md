# Cass-style Session Search

This repo provides a small helper, `cass-session-search`, to make prior
coding-agent sessions searchable from terminal environments that use this
flake.

## Command

```bash
cass-session-search [--roots] [RG_ARGS...] PATTERN
```

Examples:

```bash
cass-session-search router dashboard
cass-session-search --fixed-strings 'agent-guards.nix'
cass-session-search --roots
```

The command is a thin wrapper around `ripgrep` that targets local agent
session directories.

## Session Roots

By default, the following roots are searched (when they exist):

- `$HOME/.copilot/session-state` (GitHub Copilot CLI sessions)
- `$HOME/.claude/sessions` (Claude Code sessions)
- `$HOME/.gemini/history` (Gemini CLI per-project history)

You can override the roots by setting `CASS_SESSION_ROOTS` to a
colon-separated list of directories before running the command.

## Rollout Model

- **Host-local only**: the search operates on local session files and does
  not talk to any remote service.
- **No automatic docs export**: results stay in the terminal; this command
  does not write back into the repo or other documentation.

## Privacy and Retention

- All data searched is already present on the local machine under your
  normal user account.
- The command does not transmit session content over the network.
- If you want to exclude specific directories, either remove them from
  `CASS_SESSION_ROOTS` or point `CASS_SESSION_ROOTS` at a narrower set of
  paths.

## Refreshing the Index

`cass-session-search` does not maintain its own index; it searches the
current contents of the configured session directories each time it runs.
To "refresh" the view, ensure your agent tools have flushed their latest
sessions to disk and rerun the search command.
