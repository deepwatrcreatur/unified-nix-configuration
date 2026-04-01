# Router nixos-anywhere Bootstrap — Lessons Learned

Captured from the first successful install of the `router` NixOS host onto
pve-z170 (VM 200), replacing the old opnsense/gateway setup.

---

## 1. Bootloader priority conflict with inherited config

**Problem:** The gateway configuration set `boot.loader.limine.enable =
lib.mkForce false` (priority 50) to keep GRUB. The router configuration
overrode it with `boot.loader.limine.enable = true` (priority 100 — the
default). Priority 100 loses to priority 50, so nixos-anywhere silently
installed the `no-bootloader` stub. The VM booted but found no bootloader.

**Fix:** Use `lib.mkOverride 49 true` in the child config to beat priority 50
without triggering a same-priority conflict error.

**Current state:** Gateway inheritance is gone. Router configuration is now
standalone with `boot.loader.limine.enable = true` at default priority, so
this conflict cannot recur.

---

## 2. SSH agent exhaustion on the live ISO

**Problem:** The workstation SSH agent offered many keys to the live ISO's
`sshd`. The ISO's default `MaxAuthTries` is low, so the connection was
rejected with "Too many authentication failures" before the right key was
tried.

**Fix:** Clear `SSH_AUTH_SOCK` before connecting to the live ISO:
```bash
SSH_AUTH_SOCK="" ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 root@<ip>
```

The `just install` recipe should also be run with `SSH_AUTH_SOCK=""`:
```bash
SSH_AUTH_SOCK="" just install router <ip> "" "" true
```

---

## 3. attic-cache unreachable during build (DNS chicken-and-egg)

**Problem:** The local nix daemon has `attic-cache` configured as a
substituter by hostname. When the router is not yet up, DNS resolution fails.
nixos-anywhere falls back to building everything locally, which takes a very
long time.

**Fix:** Pass the attic-cache IP directly via `NIX_CONFIG` before invoking
nixos-anywhere:
```bash
TOKEN=$(sudo cat /run/agenix/attic-client-token)
cat > /tmp/attic-bootstrap-netrc <<EOF
machine 10.10.11.39
  password $TOKEN
EOF

NIX_CONFIG="
extra-substituters = http://10.10.11.39:5001/cache-local
extra-trusted-public-keys = cache-local:GozZz7XFsUZ7xI5o/Q36JA/BFfjzONWOjiqC+zAhp2g=
netrc-file = /tmp/attic-bootstrap-netrc
" SSH_AUTH_SOCK="" just install router <ip> "" "" true
```

The `bootstrap-nixos-router.yml` Ansible playbook wraps this with
`-e use_attic_cache=true`. The `bootstrap-nixos-inference.yml` playbook has
the same optional flag.

**attic-cache constants:**
- IP: `10.10.11.39:5001`
- Public key: `cache-local:GozZz7XFsUZ7xI5o/Q36JA/BFfjzONWOjiqC+zAhp2g=`
- Token: `/run/agenix/attic-client-token` on any NixOS host with agenix

---

## 4. Management interface not reachable post-install

**Problem:** During the ISO boot, `ens18` (the management virtio NIC) gets a
DHCP address on 10.10.0.0/16 from opnsense. After nixos-anywhere installs and
the VM reboots into NixOS, `ens18` is configured as a static
`192.168.100.100/24` — a separate management subnet that doesn't exist in the
homelab yet. The DHCP lease from opnsense is gone; no path to the VM.

**Fix options (pick one):**

A. Add a temporary address to the control machine's LAN NIC:
```bash
sudo ip addr add 192.168.100.1/24 dev <lan-nic>
ssh deepwatrcreatur@192.168.100.100
```

B. Connect the I226-V LAN port to the LAN switch. The router comes up at
`10.10.10.1`. `ssh deepwatrcreatur@10.10.10.1` works from any LAN host
(same L2 segment, no routing needed).

**Note:** Option B also starts the router's DHCP/DNS services (Technitium),
which may conflict with opnsense. Only do this when ready to cut over.

---

## 5. NixOS console login not possible without a password

The NixOS configuration does not set a root or user password. Console access
via Proxmox noVNC/VNC gives a login prompt but no way in. This is by design
for SSH-only hosts but means you have no fallback if the network is
misconfigured.

**Mitigations:**
- Always verify the management IP is reachable **before** the install
  completes (check from the control machine while the ISO is still running).
- Consider adding `users.users.root.initialHashedPassword` to the
  configuration for a temporary password during bootstrap, removed after
  first successful SSH login.
- The Proxmox QEMU serial console (`qm terminal <vmid>`) is the other
  fallback, but requires the VM to have a serial device configured and a
  getty on `ttyS0`.

---

## 6. Machine identity cleanup timing

The `just install` recipe removes `/tmp/nix-bootstrap-<host>/` after
nixos-anywhere exits successfully. If the nixos-anywhere command completes
(VM reboots) but the shell session is interrupted before the cleanup message,
the key is already gone. This is correct behavior but can be confusing.

**Recovery:** If the key is gone but the install completed, recover from the
installed system:
```bash
# Mount the installed btrfs disk from the live ISO
mount -o subvol=@ /dev/sda2 /mnt
cat /mnt/var/lib/agenix/machine-identity  # private key
ssh-keygen -y -f /mnt/var/lib/agenix/machine-identity  # derive public key
```

---

## 7. NIC naming on the router VM

The I226-V dual-port NIC via PCI passthrough gets PCI-bus-derived names:

| Interface | NIC | Role |
|-----------|-----|------|
| `enp1s0`  | I226-V hostpci0 (0000:03:00.0) | LAN |
| `enp2s0`  | I226-V hostpci1 (0000:04:00.0) | WAN |
| `ens18`   | virtio management (Proxmox) | Management |

These were confirmed by booting the live ISO and running `ip a`. The names
are now hardcoded in `hosts/nixos/router/configuration.nix`.
