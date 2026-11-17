# Adding a NixOS host

One checklist for bringing a new machine into this repo, from inspecting the
hardware to first boot. It links to the detailed guides instead of repeating
them:

- [`agenix-add-host-guide.md`](./agenix-add-host-guide.md): machine identities
  and recipient groups.
- [`nixos-anywhere-bootstrap.md`](./nixos-anywhere-bootstrap.md): the
  `just gen-identity` / `just rekey` / `just install` workflow.
- [`router-nixos-anywhere-lessons.md`](./router-nixos-anywhere-lessons.md):
  install pitfalls (SSH agent, attic cache, unreachable management IP).

Worked example: commit `41346686` (add `elitedesk`, a bare-metal router host)
and its rekey `5cb16f7d`. The reverse, removing a host, is `eb4ce343`
(router-backup) and its rekey `5fa2575c`.

## 1. Inspect the machine

From whatever it runs today (Proxmox, a live ISO, an old distro):

```sh
lspci -nnk | grep -A3 -i ethernet      # NIC models and drivers
ip -br link                            # interface names and MACs
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS
ls -l /dev/disk/by-id/ | grep -v part  # stable disk ids for disko
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
grep -r . /etc/modprobe.d/             # driver options the old OS needed
```

- Record each NIC's MAC; pin names with `systemd.network.links` so a PCI
  change cannot rename them.
- Carry over module options the old OS needed. Example: an Oracle-branded
  Intel X520 needs `options ixgbe allow_unsupported_sfp=1`, or third-party
  SFP+ modules show no carrier.
- Unused NIC ports on Proxmox are administratively down. No link light or
  laser does not mean a fault; `ip link set <if> up` and check
  `ethtool <if>` and `ethtool -m <if>` before blaming cables or optics.
- Note anything on the disks that must survive (VM disks, ZFS pools).
  `just install` wipes every disk named in `disko.nix`.

## 2. Pick addresses

- Check an address is free before using it: ping it from `router` and look
  at `ip neigh` there. A MAC starting `bc:24:11` is a Proxmox VM.
- Management addresses are in `192.168.100.0/24`; emerald reaches that subnet
  through `router`.

## 3. Files to add or edit

| File | What |
| --- | --- |
| `lib/hosts.nix` | Operational metadata: `ip`/`sshHostname`, `sshUser`, `includeDns`, description |
| `den/inventory/hosts.nix` | `system`, `hostPath`, `isDesktop`, `aspectsList` |
| `den/hosts/<host>/default.nix` | den leaf: `mkInventoryHostModule` with the host's imports |
| `hosts/nixos/<host>/hardware-configuration.nix` | initrd modules, kernel modules, modprobe options |
| `hosts/nixos/<host>/disko.nix` | disk layout by `/dev/disk/by-id/...` |
| `hosts/nixos/<host>/configuration.nix` | host wiring (NIC links, roles, mounts) |
| `users/deepwatrcreatur/hosts/<host>/default.nix` | Home Manager overlay for the host |
| `ansible/inventory/hosts.yml` | `ansible_host` and `flake_target` |
| `secrets.nix` | recipient groups (step 4) |
| `lib/remote-builder.nix` | `nixosHosts`, if it should use the remote builder |
| `modules/nixos/services/gatus-inventory.nix` | grouping, if the name is not classified already |
| `docs/agenix-machine-identity-inventory.md`, `docs/agenix-machine-identity-dashlane.txt` | identity records |

Host names must match between `lib/hosts.nix` and `den/inventory/hosts.nix`;
the `inventory-consistency` check enforces it.

## 4. Identity and secrets

```sh
just gen-identity <host>   # public key into ssh-keys/agenix-machine-identities/
# add <host> to the right groups in secrets.nix
just rekey
```

- The private key stays at `/tmp/nix-bootstrap-<host>/machine-identity` until
  `just install` copies it into the new system and deletes it. Store it in
  Dashlane as `agenix machine identity - <host>` first.
- Verify recipients without printing secrets: decrypt each
  `secrets-agenix/*.age` with `age -d -i <private key>` to `/dev/null` and
  list which succeed. Confirm the operator key still opens all of them.
- Commit the host and the rekey separately; the rekey diff is large.

## 5. Validate before install

```sh
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
nix build .#nixosConfigurations.<host>.config.system.build.diskoScript
nix build .#checks.x86_64-linux.inventory-consistency
nix build .#checks.x86_64-linux.module-loading-eval
```

If you touched shared modules, compare the values you changed on the other
hosts that use them (`nix eval` before and after). Comparing `drvPath` is not
enough, because some units embed the repo's source path and change on every
commit.

## 6. Install

Deal with existing VMs and data first; see step 1. Then:

```sh
# arguments are positional: host target hw disk accept_new
SSH_AUTH_SOCK="" just install <host> <current-ip> "" "" true
```

`nixos-anywhere` can install from a running Linux system (it kexecs into an
installer), so a Proxmox node does not need a live ISO. After reboot the host
comes up on the addresses in its config, not the old one.

## Router hosts

A host that imports `hosts/nixos/router/role.nix` while `router` is still
primary must not compete with it on the LAN or WAN. `elitedesk`'s
`configuration.nix` is the pattern:

- `ownLanServices = false`: no Kea, DDNS, UPnP or RA ownership.
- IPv6 RA and prefix delegation off on LAN and management.
- WAN interface `ActivationPolicy = "down"`: with DHCP on, it could take the
  cable modem's only lease from `router`.
- Tailscale, iVentoy and the mDNS reflector off.
- Technitium keeps running, without DHCP scopes, reservations or NTP pushes.
- `managementDevice` passed to `role.nix` when it is not `ens18`.

Promotion to primary reverses these and is a separate change; see
[`design/router-election/README.md`](./design/router-election/README.md).
