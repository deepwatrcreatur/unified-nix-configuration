# 34 Vaglio Proxmox LXC Bring-Up

Status: `done`
Suggested branch: `feat/vaglio-proxmox-lxc-bring-up`
Priority: `high`

## Goal

Create or recover the actual Proxmox LXC guest for `vaglio` so there is a real
host behind the repo inventory entry and a machine that can be administered with
`pct enter`.

## Why

- Repo inventory models `vaglio` as a NixOS LXC host.
- Proxmox cluster inspection on May 10, 2026 showed no current LXC definition
  for `vaglio` in `/etc/pve/nodes/*/lxc/*.conf`.
- Without a real guest, follow-on work is blocked:
  - machine identity generation
  - Roundtable secret rekeying
  - `homeserver-roundtable` reattachment
  - `/forgejo-shell` demo deployment

## Scope

1. Choose the Proxmox node that should host `vaglio`.
   Current pragmatic default: `pve-tomahawk`, because it is reachable now and
   already hosts the other active homelab LXCs.
2. Create a fresh NixOS LXC guest named `vaglio` with DHCP on `vmbr0`.
3. Bootstrap it to the point where SSH access works and `pct enter <vmid>` is
   available from the owning node.
4. Generate `/var/lib/agenix/machine-identity` in the guest and commit
   `ssh-keys/agenix-machine-identities/vaglio.pub`.
5. Record the chosen VMID/node and any one-time Proxmox details in repo docs.

## Non-Goals

- Attaching the Roundtable service itself
- Creating `roundtable-secret-key-base.age`
- Designing Forgejo-shell or the code-analysis demo

## Proposed Bring-Up Path

1. Use the standalone `vaglio` profile from the adjacent `agent-roundtable`
   repo as the initial service shape.
   It already provides:
   - `services.roundtable.enable = true`
   - `git`, `gh`, `dolt`, `jujutsu`, and `tmux`
   - an LXC-oriented profile in `nix/modules/profiles/vaglio-lxc.nix`
2. Prefer a fresh CT over trying to infer a deleted one from inventory alone.
3. Start with the repo's existing NixOS LXC bootstrap pattern if the standalone
   Vaglio profile is not used directly:
   - `.#nixos_lxc_without_determinate` for initial bring-up
   - then switch to the steady-state config
4. Once the guest is reachable:
   - create `/var/lib/agenix/machine-identity`
   - copy back the public key
   - proceed to work item 30 for Roundtable reactivation

## Concrete Bring-Up Sequence

As of May 10, 2026, `pve-tomahawk` is the best default host because:
- it is reachable now
- it already hosts the active NixOS LXCs
- it already has a NixOS Proxmox LXC template cached at
  `local:vztmpl/nixos-image-lxc-proxmox-25.11pre-git-x86_64-linux.tar.xz`

Suggested values:
- Proxmox node: `pve-tomahawk`
- VMID: re-check with `pvesh get /cluster/nextid` before creation
  - current observed next ID on May 10, 2026: `104`
- MAC address: `BC:24:11:A4:02:7A`
  - this matches the DHCP reservation already recorded for `vaglio`

Create the CT on `pve-tomahawk`:

```bash
CTID=$(pvesh get /cluster/nextid)
TEMPLATE='local:vztmpl/nixos-image-lxc-proxmox-25.11pre-git-x86_64-linux.tar.xz'

pct create $CTID $TEMPLATE \
  --hostname vaglio \
  --ostype nixos \
  --unprivileged 1 \
  --features nesting=1 \
  --cores 2 \
  --memory 5512 \
  --swap 512 \
  --rootfs rpool-data:60 \
  --net0 name=eth0,bridge=vmbr0,firewall=1,hwaddr=BC:24:11:A4:02:7A,ip=dhcp,ip6=auto,type=veth \
  --onboot 1 \
  --ssh-public-keys /root/.ssh/authorized_keys \
  --start 1
```

Initial verification from the Proxmox node:

```bash
pct config $CTID
pct exec $CTID -- sh -lc 'hostname; ip -4 addr show dev eth0'
pct enter $CTID
```

Inside the container, bootstrap the standalone Vaglio profile first:

```bash
mkdir -p /root/flakes
cd /root/flakes
git clone https://github.com/deepwatrcreatur/agent-roundtable.git
cd agent-roundtable
nixos-rebuild switch --flake .#vaglio
```

Still inside the container, create the stable agenix machine identity:

```bash
install -d -m 700 /var/lib/agenix
test -f /var/lib/agenix/machine-identity || \
  ssh-keygen -t ed25519 -N '' -C 'agenix-machine-identity vaglio' -f /var/lib/agenix/machine-identity
chmod 400 /var/lib/agenix/machine-identity
cat /var/lib/agenix/machine-identity.pub
```

Then, back in this repo:

```bash
ssh root@10.10.11.71 'cat /var/lib/agenix/machine-identity.pub' > ssh-keys/agenix-machine-identities/vaglio.pub
git add ssh-keys/agenix-machine-identities/vaglio.pub
```

After that, proceed to work item 30:
- create and rekey `roundtable-secret-key-base.age`
- reattach `homeserver-roundtable` to `vaglio`
- switch from the standalone `agent-roundtable` profile to the inventory-backed
  `unified-nix-configuration#vaglio` host path

## Validation

- Proxmox cluster config contains a `vaglio` LXC definition
- `pct enter <vmid>` succeeds on the owning node
- `ssh deepwatrcreatur@10.10.11.71` or the final assigned host address works
- `ssh-keys/agenix-machine-identities/vaglio.pub` exists in this repo

## Notes

This item exists because the repo currently has a host definition without a
corresponding live Proxmox guest. Fixing that mismatch is the cleanest next
move and requires little design discussion.

Execution notes from May 10, 2026:

- `vaglio` was created on `pve-tomahawk` as CT `104`
- the guest obtained the expected DHCP address `10.10.11.71`
- `/var/lib/agenix/machine-identity` was generated in the guest
- `ssh-keys/agenix-machine-identities/vaglio.pub` was copied back into this repo
- the standalone `agent-roundtable` `#vaglio` profile switches successfully
- `roundtable.service` does not work out of the box in that standalone profile:
  - the generated start script assumes `CREDENTIALS_DIRECTORY` exists under `set -u`
  - the packaged `roundtable-web` path runs Mix from a read-only `/nix/store`
    source tree and fails during Hex dependency setup with `{:error, :erofs}`
- a runtime-only systemd override on `vaglio` now points `roundtable.service`
  at the writable checkout in `/root/flakes/agent-roundtable/roundtable`
- with that runtime override, `roundtable.service` is active and `HEAD /`
  returns `200 OK` on port `4000`
- that override lives under `/run/systemd/system/roundtable.service.d/` and is
  therefore not persistent across reboot; the proper fix belongs in the
  `agent-roundtable` repo
