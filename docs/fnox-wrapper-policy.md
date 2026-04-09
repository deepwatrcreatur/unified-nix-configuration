# Fnox Wrapper Policy

This policy defines when and how commands should be wrapped with `fnox` within the `unified-nix-configuration` repository.

## When to Wrap

Wrap a command only when it meets **one or more** of these criteria:

1.  **Frequent Secret Dependency**: The command regularly requires an API token, password, or session key that is managed via SOPS or Agenix (e.g., `gh`, `bw`, `pbs`).
2.  **Stable Policy Defaults**: The command requires complex, repo-specific flags to function correctly in our environment (e.g., specific repository paths or endpoint URLs).
3.  **Cross-Host Portability**: The wrapper provides a consistent interface for a tool whose secret location might differ between macOS and Linux.

## What NOT to Wrap

Do not wrap the following categories:

- **Generic Build Tools**: Commands like `nixos-rebuild`, `nh`, `nix`, or `just`. These should remain raw to avoid circular dependencies and unexpected side effects.
- **Pure Utility Commands**: Standard Unix utilities (`ls`, `grep`, `find`) unless there is a critical repo-specific security reason.
- **Interactive Shells**: Do not wrap `bash`, `fish`, or `zsh` itself.

## Implementation Pattern

To ensure reliability and clarity, all wrappers must follow these rules:

### 1. Canonical Name Preference
Wrappers should be available via their canonical name (e.g., `gh`) to make them transparent to the operator. They should also provide a suffixed name (e.g., `gh-fnox`) for explicit calls.

### 2. Idempotent Injection
Wrappers must check if the relevant environment variable is *already* set. If it is, the wrapper must not overwrite it. This allows for manual overrides during debugging.

```bash
if [ -z "${GH_TOKEN:-}" ]; then
  # Only then try to source it via fnox
fi
```

### 3. Graceful Fallback
If a repo-managed token file exists, wrappers should prefer that durable file
path first. `fnox` remains the fallback lookup path when the managed file is
absent or empty, before finally executing the raw command.

### 4. Minimal Dependencies
Prefer `writeShellApplication` with specific `runtimeInputs` to ensure the wrapper is self-contained and does not rely on global system state.

## Current Wrappers

| Tool | Wrapper Name | Secrets Injected |
| :--- | :--- | :--- |
| `gh` | `gh-fnox` | `GH_TOKEN` / `GITHUB_TOKEN` |
| `bw` | `bw-fnox` | `BW_SESSION` |
| `attic` | `attic-fnox` | `ATTIC_CLIENT_JWT_TOKEN` |
| `pbs` | `proxmox-backup-client-fnox` | `PBS_PASSWORD`, `PBS_REPOSITORY` |
| `droid` | `factory-droid-fnox` | `FACTORY_API_KEY` |

## Policy Enforcement

- Future agents adding new wrappers must update this policy document.
- Wrappers that deviate from this pattern should be refactored or documented as intentional exceptions.
