# Inference VM Bootstrap

This is the first-install path for `inference1`, `inference2`, and `inference3`.
It assumes:

- the VM has already been provisioned in Proxmox
- the VM is booted into a NixOS live installer
- SSH access to the live installer works

## What the repo now expects

The shared inference VM configuration is built around:

- `disko` for partitioning and formatting
- UEFI + Limine
- Btrfs on the full root partition
- Snapper for `/` and `/home`
- stable SSH access for `deepwatrcreatur` and `root`
- a dedicated agenix machine identity at `/var/lib/agenix/machine-identity`

Shared storage layout lives in:

- `hosts/nixos/inference-vm/modules/disko.nix`

Generated per-host hardware data is written into:

- `hosts/nixos/inference-vm/hosts/<host>/hardware-configuration.nix`

Stable agenix machine identity public keys are stored in:

- `ssh-keys/agenix-machine-identities/<host>.pub`

## Disk layout

The shared `disko` layout creates:

- `ESP`: 1 GiB vfat mounted at `/boot`
- `root`: remaining disk as Btrfs

Btrfs subvolumes:

- `@` mounted at `/`
- `@home` mounted at `/home`
- `@snapshots` mounted at `/.snapshots`

The install path assumes a single Proxmox system disk exposed as:

`/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0`

Override `install_disk_device` in Ansible if the VM uses a different path.

## Bootstrap command

From the repo root:

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/bootstrap-nixos-inference.yml --limit inference1
```

For a different live-installer SSH user or disk path:

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/bootstrap-nixos-inference.yml \
  --limit inference1 \
  -e install_ssh_user=nixos \
  -e install_disk_device=/dev/vda
```

## What the playbook does

1. Runs `nixos-anywhere` from the control machine against the live installer.
2. Refreshes `hardware-configuration.nix` for the target host.
3. Generates `/var/lib/agenix/machine-identity` on the installed host if missing.
4. Copies the matching public key into `ssh-keys/agenix-machine-identities/<host>.pub`.
5. Rekeys agenix secrets locally with `nix run github:ryantm/agenix -- -r`.
6. Prints `git status --short` so the resulting repo changes can be reviewed.

## Expected review after install

The playbook intentionally updates the repo working tree. Review and commit:

- refreshed `hardware-configuration.nix`
- new `ssh-keys/agenix-machine-identities/<host>.pub`
- any `.age` files touched by rekeying

Then push and run your normal rebuild/update path.

## Notes

- The initial install does not depend on stale filesystem UUIDs; the root layout is declarative in `disko`.
- `secrets.nix` already includes `inference1`, `inference2`, and `inference3` in the shared recipient groups that matter for first-class hosts. Once the machine public key exists and secrets are rekeyed, later rebuilds can decrypt normally with the stable machine identity.
- The placeholder `hardware-configuration.nix` files in the repo are just safe generic defaults for Proxmox/QEMU. The playbook is expected to overwrite them with generated host data.
