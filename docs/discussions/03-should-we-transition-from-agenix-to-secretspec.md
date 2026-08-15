# Discussion 03: Should We Transition from Agenix to SecretSpec?

**Status:** closed  
**Scope:** `unified-nix-configuration`  
**Date:** 2026-08-14  

## Why this discussion exists

`unified-nix-configuration` relies on `agenix` (`age` encryption keyed against SSH machine and user identities) to manage secrets across a multi-host infrastructure fleet (`router`, `router-backup`, `workstation`, `homeserver`, `proxmox`, `vaglio`, etc.):

- Secrets are encrypted as `.age` files stored in `secrets-agenix/` and committed directly to the GitHub repository.
- Key recipients are declared in `secrets.nix` using host public SSH keys (`ssh-keys/agenix-machine-identities/`) and maintainer user keys.
- Decryption happens at boot/activation via `modules/common/secrets-management.nix` (system level) and `modules/home-manager/agenix-user-secrets.nix` (user level), placing unencrypted secret files into tmpfs paths (e.g. `/run/agenix/` or `~/.local/share/agenix-user-secrets/`).

This discussion evaluates whether the repository should transition from `agenix` to [SecretSpec](https://secretspec.dev) (a declarative `secretspec.toml` standard for defining application secret contracts, profiles, and runtime injection across backends).

## Participation record & Grounding

Following the agent orchestration guidelines from `agent-roundtable` (`docs/design/ORCHESTRATION_GUIDE.md` and prior synthesis in Round 149), this discussion round synthesizes positions across the core multi-agent roster:

- **Codex CLI**
- **Gemini CLI** (via `agy`)
- **DeepSeek API**
- **Copilot / Claude IC synthesis**

### Grounding files consulted
- `unified-nix-configuration/secrets.nix`
- `unified-nix-configuration/secrets-agenix/`
- `unified-nix-configuration/modules/common/secrets-management.nix`
- `unified-nix-configuration/modules/home-manager/agenix-user-secrets.nix`
- `unified-nix-configuration/docs/agenix-workflow.md`
- `agent-roundtable/docs/design/rounds/round-149-secretspec-vs-agenix-and-infisical-for-unified-and-vaglio.md`

---

## Voice summaries

### Codex CLI

- **Core position:** Category error to view SecretSpec as a substitute for `agenix`.
- **Key points:**
  - `agenix` operates as an **encrypted-at-rest storage and host authority layer**. It binds secret decryption to hardware/SSH host identities during NixOS boot and activation.
  - SecretSpec is a **runtime consumption contract** (`secretspec.toml`). It specifies what environment variables or files an application or developer shell requires, but does not provide host key encryption, recipient mapping, or boot-time tmpfs mounting.
  - NixOS service modules depend on concrete file paths (`config.age.secrets.<name>.path`). SecretSpec offers no native NixOS module integration or boot-time decryption mechanism.
- **Verdict:** Reject transition. Maintain `agenix` for host infrastructure.

### Gemini CLI (via `agy`)

- **Core position:** Transitioning would introduce high architectural churn for zero security or operational gain.
- **Key points:**
  - `unified-nix-configuration` has already invested in standardizing on `agenix` across all hosts, eliminating previous `sops-nix` fragmentation.
  - Committing `.age` encrypted files to GitHub ensures that secret management is fully declarative, version-controlled, and self-contained within the flake repository without external server dependencies.
  - SecretSpec does not replace `.age` files—it would require either an external secret vault (e.g. HashiCorp Vault, 1Password, Infisical) or an unencrypted file backend, adding an external operational dependency to a host config repo.
- **Verdict:** Reject transition. Keep `agenix` as the single source of truth for repo secrets.

### DeepSeek API

- **Core position:** SecretSpec belongs at the app/devshell consumption boundary, not the multi-host NixOS authority boundary.
- **Key points:**
  - SecretSpec excels at developer environment ergonomics (e.g., integration with `devenv`), profile switching (dev/staging/prod), and auditing reason-for-access when agents run local CLI tasks.
  - However, in a multi-host Nix flake repo managing headless routers, hypervisors, and storage nodes, host secrets must be decrypted unattended at boot using host SSH keys.
  - If a central credential broker (such as Infisical) is adopted in the future for dynamic tokens, SecretSpec could act as an app-level layer above that broker. But for static host secrets committed to Git, `agenix` remains superior.
- **Verdict:** Do not replace `agenix`. Restrict any potential SecretSpec evaluation to isolated per-project developer shells.

### Copilot / Claude IC Synthesis

- **Core position:** Reaffirm the architectural boundary established in Round 149.
- **Key points:**
  - **Authority vs. Contract:** `agenix` is the authority layer (encrypted files + SSH recipient keys + NixOS systemd integration). SecretSpec is an interface contract (declaring what secrets a project expects at runtime).
  - Replacing `agenix` with SecretSpec in `unified-nix-configuration` would break the offline, git-native, boot-time decryption model that powers the multi-host fleet.
- **Verdict:** Reconcile by maintaining `agenix` as the mandatory secret infrastructure.

---

## Convergence

The discussion round converged on five core principles:

1. **Agenix and SecretSpec solve different problems:**
   - `agenix` = Repo-native encrypted storage at rest + host SSH key identity decryption + NixOS/Home-Manager service path delivery.
   - `SecretSpec` = Declarative application/devshell secret requirement spec + multi-provider runtime environment injection.

2. **Git-committed `.age` files remain the optimal model for this multi-host config:**
   - Encrypting secrets with `age` and committing them to the GitHub repository ensures that deployment, rebuilds, and host bootstrapping remain completely reproducible and offline-capable without relying on an external secret server.

3. **No native NixOS boot integration in SecretSpec:**
   - SecretSpec does not integrate with NixOS activation scripts, systemd credential passing, or `age.secrets` module options. Transitioning would require writing custom wrappers for every system service.

4. **Avoiding third-layer secret fragmentation:**
   - Having recently stabilized the fleet on `agenix` (moving away from legacy SOPS paths), adding SecretSpec to the host configuration layer would introduce unnecessary complexity and confusion.

5. **Bounded future role for SecretSpec:**
   - If SecretSpec is ever used in this ecosystem, its role is strictly bounded to per-project developer shells (e.g., `devenv` flakes) or standalone app repos requiring backend-agnostic runtime injection, sitting *above* host secrets or credential brokers.

---

## Maintained line

The maintained line after this round is:

- **Do NOT transition `unified-nix-configuration` from `agenix` to SecretSpec.**
- Continue using `agenix` (`secrets.nix`, `secrets-agenix/*.age`, `ssh-keys/agenix-machine-identities/`) for all host infrastructure, user environment, and service secrets committed to GitHub.
- Keep `agenix` as the sole secret authority for NixOS host definitions and appliance deployments (`router`, `workstation`, `vaglio`, etc.).
- If SecretSpec is evaluated in the future, restrict its use to app-level developer shells (`devenv`) as an optional consumption contract above settled backends, never as a replacement for host-level `agenix` encryption.

---

## Bottom line

**There is no case to transition `unified-nix-configuration` from `agenix` to SecretSpec.**

`agenix` provides the exact encrypted-at-rest, git-committed, host-identity-decrypted architecture required by a multi-host NixOS repository. SecretSpec is an application secret contract layer, not a host secret authority, and replacing `agenix` with it would degrade the security, offline reproducibility, and simplicity of the fleet.
