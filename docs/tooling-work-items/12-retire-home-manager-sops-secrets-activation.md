# 12 Retire Home Manager SOPS Secrets Activation

Status: `done`

Suggested branch: `refactor/tooling-retire-hm-sops-activation`

## Goal

Decide whether `modules/home-manager/secrets-activation.nix` is still an
intentional compatibility layer or should now be retired in favor of the
agenix-first secret path.

## Outcome

Retired `modules/home-manager/secrets-activation.nix` and moved its essential
legacy SOPS decryption and GPG import logic into `modules/home-manager/user-secrets.nix`.

What changed:
- `user-secrets.nix` now handles GPG private key, Bitwarden session, and Bitwarden data.json decryption (under `migrationMode`).
- `user-secrets.nix` now handles GPG public/private key import and trust setting.
- `secrets-activation.nix` has been removed.
- Imports and usages in `users/deepwatrcreatur/default.nix`, `users/deepwatrcreatur/hosts/inference-vm/default.nix`, and `users/root/hosts/proxmox/default.nix` have been updated to use `user-secrets.nix` exclusively.
- Documentation in `docs/agenix-first-secrets.md` and `docs/github-token-fallbacks.md` has been updated.
