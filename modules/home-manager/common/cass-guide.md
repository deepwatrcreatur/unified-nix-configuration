# CASS Session Search Guide for Agents

Past session history from Claude, Codex, Gemini, and other agents is indexed and searchable.

## Usage

- **Search**: `cass search "topic" --robot` (returns machine-readable JSON context)
- **View Session**: `cass view <path> --json`
- **Expand Context**: `cass expand <path> -n <line> -C 5 --json`

Always use the `--robot` or `--json` flags when running `cass` within an automated session to avoid launching the TUI.
