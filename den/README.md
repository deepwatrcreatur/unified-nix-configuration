# den-lxc Prototype

This is a den-inspired experiment for `unified-nix-configuration`.

It does not import `vic/den`. Instead, it prototypes a similar idea locally:

- define hosts as small entities
- compose them from named aspects
- keep cross-cutting concerns reusable
- leave the existing host tree untouched

Initial targets:

- `homeserver-den`
- `podman-den`

These outputs are intentionally low-stakes and live alongside the current layout.

The prototype also includes a migration inventory for the rest of the repo:

- NixOS hosts
- Darwin hosts
- standalone Home Manager outputs
- special bootstrap outputs

Only `homeserver` and `podman` are fully aspectized right now. The rest are represented
as migration-ready inventory entries so the prototype shape can scale to the full repo.
