# 14 DCG PreToolUse Guard

Status: `done`

## Outcome

`agent-guard` (`scripts/agent-guard.py`) is installed by
`modules/home-manager/common/agent-guards.nix` and registered as a Claude Code
`PreToolUse` hook on `Bash`, plus a Gemini CLI `BeforeTool` hook when the
Gemini rtk integration is enabled. The policy and how to bypass it are
documented in `AGENTS.md` under "Destructive command guard".

## Why it was reworked

The first version (`scripts/check-destructive.sh`) was installed but never
took effect:

- it exited 1 with a top-level `permissionDecision` field, which Claude Code
  treats as a non-blocking hook error, so commands ran without a prompt;
- substring matching on a lowercased command caused false positives
  (`git branch -d`, `git push origin feat-f`) and missed wrapped commands.

The replacement tokenizes commands with `shlex`, unwraps `ssh`, `bash -c`,
`sudo`, `env`, `xargs`, `timeout`, `systemd-run` and `pct exec`, returns
`hookSpecificOutput.permissionDecision` (`ask` or `deny`) with exit 0, and
replaces stale `agent-guard` entries in the settings files on activation.

## Validation

- `nix build .#checks.x86_64-linux.agent-guard-policy` runs the allow, ask and
  deny cases in `tests/agent-guard-test.py` and checks both hook output
  formats.
- Codex is still uncovered: its repo-managed configuration has no equivalent
  pre-execution hook.
