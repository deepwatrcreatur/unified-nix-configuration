# GitHub Token Fallback Order

This document explains how the `unified-nix-configuration` determines which GitHub token to use for flake operations and shell environments.

## Precedence (Highest to Lowest)

If multiple token sources are available, the first valid one found is used:

1.  **Agenix User Secret**: `~/.local/share/agenix-user-secrets/github-token`
    - This is the preferred source for secure, multi-host secret management.
2.  **System-Level Secret**: `/run/secrets/github-token`
    - Provisioned by the system (e.g., via Agenix or another system-wide secret manager).
3.  **Legacy SOPS User Secret**: `~/.config/git/github-token`
    - Decrypted during Home Manager activation from the local secrets directory.

## Guardrails and Health Checks

To prevent "poisoning" the token file with error messages (e.g., SOPS decryption failures), the following protections are in place:

- **Atomic Writes**: Decryption is performed to a temporary file. The target token file is only overwritten if decryption succeeds.
- **Sanity Validation**: A decrypted token is rejected and not installed if:
  - It is empty.
  - It contains multiple lines.
  - It contains any whitespace characters.
- **Auto-Cleanup**: If no valid source is found during activation, any existing *invalid* token file at `~/.config/git/github-token` is removed to prevent misleading failure modes in shells.

## Configuration

These paths and behaviors are managed by:
- `modules/home-manager/user-secrets.nix`: Handles fallback logic, sanity checks, and legacy SOPS-based decryption for hosts still in transition.
