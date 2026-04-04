# Agenix-First Secret Architecture

This document describes the repo's transition from SOPS-based user secret activation to a stable, agenix-first design.

## Target Design (Agenix-First)

In the stable state, secrets are provisioned by the system or agenix-user-secrets before Home Manager activation runs.

1.  **System Secrets**: Managed by agenix at the NixOS level, typically residing in `/run/secrets/`.
2.  **Agenix User Secrets**: Managed by agenix-user-secrets, typically residing in `~/.local/share/agenix-user-secrets/`.
3.  **Token Fallback**: Applications and wrappers follow a strict precedence:
    - Agenix User Secret (Highest)
    - System Secret
    - Legacy SOPS File (Lowest, Migration only)

## Migration Layer (Legacy SOPS)

For hosts not yet fully migrated to agenix, a legacy SOPS activation layer exists. This layer is controlled by the `services.user-secrets.migrationMode` option.

### Guardrails

To prevent the "broken secret" failure mode (where a file contains a decryption error instead of a token):

- **Sanity Checks**: Every secret file is validated before installation. If a file is empty, multiline, or contains whitespace, it is rejected.
- **Atomic Writes**: Decryption happens to a temporary file. The target is only overwritten if the sanity check passes.
- **Auto-Cleanup**: If no valid secret source is found, any existing invalid legacy file is removed to ensure a clean failure rather than a misleading success.

## Responsibility Split

- `modules/home-manager/user-secrets.nix`: Handles the high-level fallback logic and sanity checks.
- `modules/home-manager/secrets-activation.nix`: Provides the low-level SOPS decryption implementation (Legacy).
- `modules/helpers/optional-secrets.nix`: Provides system-level agenix helpers.
