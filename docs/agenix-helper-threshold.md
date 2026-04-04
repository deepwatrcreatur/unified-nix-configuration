# Agenix Helper Flake Threshold

This document defines the criteria for extracting agenix-related helper patterns from `unified-nix-configuration` into a reusable Nix flake.

## Current Patterns

| Pattern | Category | Status | Recommendation |
| :--- | :--- | :--- | :--- |
| **Optional Secrets** | Utility | Stable | **Extract Candidate** |
| **User Secret Activation** | Home Manager | Transitional | Stay Local |
| **Token Fallback Path** | Shell/Policy | Unstable | Stay Local |
| **Fnox Integration** | Interop | Repo-Specific | Stay Local |

### 1. Optional Secrets (`mkSecrets`)
The logic in `modules/helpers/optional-secrets.nix` is a pure utility. It allows configurations to evaluate even when secrets are missing. This is highly reusable and has a very small, stable interface.

### 2. User Secret Activation
The logic for decrypting user-level SOPS/Agenix secrets is currently tied to this repo's specific directory structure and migration needs (`migrationMode`). It is not yet stable enough for general use.

### 3. Token Fallback and Fnox Integration
Precedence rules for `GITHUB_TOKEN` and integration with `fnox` seed sources are tightly coupled to how this repository manages its user environment. These should remain local implementation details.

## Threshold for Extraction

A pattern should only be considered for extraction into a separate flake when **all** of the following conditions are met:

1.  **Repeated Requirement**: The same logic is needed in at least **three** distinct repositories.
2.  **Stable Interface**: The module or helper has not required a breaking change in its option schema for at least **3 months**.
3.  **Zero Migration Debt**: The logic does not contain "if-then-else" branches for legacy backends (like SOPS).
4.  **Decoupled Logic**: The helper does not rely on repo-specific paths, users, or host naming conventions.

## Current Recommendation (Below Threshold)

**Stay Local.**

While `optional-secrets.nix` is technically ready, extracting it alone creates unnecessary overhead. The more complex activation logic is still in a transitional state. We should revisit this only after:
- At least two other "flakes" repos need the same `mkSecrets` logic.
- The `migrationMode` logic in `user-secrets.nix` is removed after all hosts are confirmed agenix-first.

## Follow-up Actions

- Move `modules/helpers/optional-secrets.nix` to a more prominent `lib/` directory within this repo to signal its high quality.
- Annotate `user-secrets.nix` logic that is intentionally non-portable.
