# Memory Archive

This directory contains extracted technical findings from agent session logs.

## Contents

Each `.md` file corresponds to one Claude Code session and contains excerpts
scored as likely technical findings (NixOS configs, error root causes, fixes).

Files are named: `YYYY-MM-DD-<session-prefix>-<project>.md`

## Generating / Updating

```bash
# Extract findings from the last 30 days (default):
python3 scripts/memory-extract.py

# Include older sessions:
python3 scripts/memory-extract.py --since 90

# Raise the quality threshold (fewer, higher-confidence findings):
python3 scripts/memory-extract.py --min-score 3

# Preview without writing:
python3 scripts/memory-extract.py --dry-run
```

## Searching

Use any full-text search tool on this directory:

```bash
# qmd (semantic search, if installed):
qmd search "router firewall nftables" docs/memory/

# grep (fast literal):
grep -r "nixos-rebuild\|flake.lock" docs/memory/

# ripgrep (recursive):
rg "kernel module" docs/memory/
```

## Retention Policy

- Archive files represent point-in-time snapshots; they may be stale.
- Delete files older than 6 months unless they contain permanently useful
  reference information.
- Do not commit files that contain redacted markers (`[REDACTED]`) in
  position where the actual value is needed — those are too degraded to be
  useful and should be removed.
- Do not commit files containing personal API keys, tokens, or passwords.

## Credential Filter

`memory-extract.py` redacts common credential patterns automatically.
If you find a committed file with sensitive data, remove it with:

```bash
git rm docs/memory/<file>
git commit -m "security: remove sensitive memory archive file"
```
