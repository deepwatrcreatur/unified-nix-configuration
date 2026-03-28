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

## Firmware and Proxmox VM requirements

The shared inference VM profile assumes UEFI + Limine.

On Proxmox, for each inference VM:

- Set `bios: ovmf` (UEFI) and use a `q35` machine type.
- Do not enable Secure Boot or pre-enrolled keys.
- Do not attach a persistent `efidisk0`.
- Use a single installer ISO as the first boot device and the system disk second.
- Attach a NixOS installer ISO and boot it in UEFI mode. Inside the live system, `test -d /sys/firmware/efi` should succeed.

The working reference here is VM `5573`: plain OVMF, no `efidisk0`, temporary EFI vars.

VM `103` demonstrated the failure mode to avoid:

- an `efidisk0` with `pre-enrolled-keys=1` enabled OVMF Secure Boot and rejected the NixOS installer and Limine EFI binaries
- a stale persistent EFI vars disk left OVMF with no usable boot entries
- with disk-first boot, OVMF then reported `no bootable option`

If you boot the installer in legacy BIOS/SeaBIOS mode, `nixos-anywhere`/`nixos-install` will fail to install the Limine EFI boot entry (you will see `efibootmgr` errors and `Failed to install bootloader`).

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
2. Verifies that the live installer is actually booted in UEFI mode.
3. Refreshes `hardware-configuration.nix` for the target host.
4. Copies Limine's EFI binary to `/boot/EFI/BOOT/BOOTX64.EFI` on the installed host so OVMF has a fallback path even without persistent EFI variables.
5. Generates `/var/lib/agenix/machine-identity` on the installed host if missing.
6. Copies the matching public key into `ssh-keys/agenix-machine-identities/<host>.pub`.
7. Rekeys agenix secrets locally with `nix run github:ryantm/agenix -- -r`.
8. Prints `git status --short` so the resulting repo changes can be reviewed.

## Expected review after install

The playbook intentionally updates the repo working tree. Review and commit:

- refreshed `hardware-configuration.nix`
- new `ssh-keys/agenix-machine-identities/<host>.pub`
- any `.age` files touched by rekeying

Then push and run your normal rebuild/update path.

## Day-2 rebuilds (remote)

After bootstrap, do not rely on GitHub access from the inference VMs.
Run rebuilds from the control machine using `--target-host`:

```bash
nixos-rebuild switch \
  --flake .#inference1 \
  --target-host deepwatrcreatur@10.10.11.131 \
  --use-remote-sudo
```

Repeat for `inference2` / `inference3` with the appropriate IPs.

## Notes

- The initial install does not depend on stale filesystem UUIDs; the root layout is declarative in `disko`.
- `secrets.nix` already includes `inference1`, `inference2`, and `inference3` in the shared recipient groups that matter for first-class hosts. Once the machine public key exists and secrets are rekeyed, later rebuilds can decrypt normally with the stable machine identity.
- The placeholder `hardware-configuration.nix` files in the repo are just safe generic defaults for Proxmox/QEMU. The playbook is expected to overwrite them with generated host data.
- Limine is configured as the primary bootloader with EFI support; all inference VMs are expected to boot via UEFI so that Limine and snapper-backed Btrfs snapshots work consistently across hosts.
- The bootstrap playbook now also installs the standard fallback path at `/boot/EFI/BOOT/BOOTX64.EFI`. That avoids depending on persistent OVMF NVRAM entries for first boot.
- If you deviate from the playbook and run `nixos-install` manually, make sure the live installer is in UEFI mode and either provide a machine identity under `/var/lib/agenix` or temporarily disable agenix-dependent activation for the first boot.
