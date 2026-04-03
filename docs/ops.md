# Operations Notes

Operational notes that matter for rebuild workflows and host safety.

## LXC Safety

- Do not locally switch the `attic-cache` guest from `workstation`.
  `attic-cache` is a Proxmox LXC guest, and running a local `nixos-rebuild test` or
  `switch` for `.#attic-cache` on `workstation` can disrupt the desktop session.

## attic-cache Workflow

Preferred workflow:

```bash
ssh attic-cache
cd ~/flakes/unified-nix-configuration
git pull --ff-only
nixos-rebuild switch --flake .#attic-cache
```

Alternative workflow from another machine:

```bash
cd ~/flakes/unified-nix-configuration
just remote-test attic-cache
just remote-switch attic-cache
```

## Remote Rebuilds

For remote-only targets such as LXC guests:

- prefer `just remote-test <host>` before `just remote-switch <host>`
- use `--target-host` based rebuilds instead of switching the target locally

## Proxmox Home Manager Leaves

Proxmox root Home Manager outputs follow the leaf naming convention:

- host: `pve-tomahawk`
- home output: `pve-tomahawk-root`

The generic update path on a Proxmox node is:

```bash
home-manager switch --flake .#$(hostname)-root
```

<<<<<<< HEAD
## Router Management Plane

The router management interface (`ens18`, `192.168.100.0/24`) is the **supported
recovery plane**. It is intentionally independent of WAN and LAN state.

**Recovery guarantees:**

- SSH and all diagnostic services bind to `0.0.0.0`; they are reachable on
  management even when WAN is absent or the LAN cable is unplugged.
- `192.168.100.100` (router) and `192.168.100.99` (router-backup) are derived
  from `lib/hosts.nix` — no raw literals in host config files.
- Grafana, Prometheus, Netdata, Caddy, and the router dashboard all bind to
  all interfaces.
- fail2ban exempts `192.168.100.0/24` from bans so authentication testing
  from management can never lock you out.

**When the router is broken and you cannot reach `10.10.10.1`:**

1. SSH via management: `ssh deepwatrcreatur@192.168.100.100`
2. Dashboard via management: `http://192.168.100.100:8888/`
3. Grafana: `http://192.168.100.100:3001/`
4. Prometheus: `http://192.168.100.100:9090/`
5. Technitium DNS admin: `http://192.168.100.100:5380/`
6. Last resort: Proxmox console → Serial Terminal 0 (ttyS0, 115200 baud)

**Design rule:** any new service added to the router role must be reachable on
the management interface. Do not bind router services exclusively to the LAN IP.

## Router Standby / Dev Mode

Both `router` and `router-backup` are designed to boot into a debuggable state
even with all production cables unplugged.

**What this means in practice:**

- The production LAN static IP (`10.10.10.1/16`) is configured with
  `ConfigureWithoutCarrier = true`, so it remains present even when the
  data-plane NIC has no link.
- Management IP is on a separate NIC (`ens18`) and is independent of WAN/LAN
  carrier state.
- Monitoring services (Prometheus, Grafana, Netdata) come up in a
  degraded-but-functional state once the LAN address exists, even if no LAN
  traffic flows.
- The serial console (`ttyS0` at 115200 baud) is always enabled as a recovery
  path when SSH or the graphical console is unavailable (Proxmox → Console →
  Serial Terminal 0).

**When swapping to the backup router:**

1. Unplug WAN and LAN cables from the production router.
2. Plug them into the backup router.
   Current interface names differ by host:
   - `router`: WAN `enp6s17`, LAN `enp6s16`
   - `router-backup`: WAN `enp2s0`, LAN `enp3s0`
3. Both routers share the same production LAN identity (`10.10.10.1`), so no
   DNS or DHCP reconfiguration is needed on clients.
4. Use the management IP to reach the new active router after cutover.

**If monitoring looks broken after unplugging cables:**

Prometheus and Grafana bind to `0.0.0.0` and should come up once the LAN
address is present. If a service is stuck in `activating`, check
`systemctl status <service>` — it may be waiting on the log storage mount
(`/var/log/router`) rather than on the LAN address.

## Git / Agent Notes

- Agents should commit without GPG signing to avoid pinentry failures.
- Prefer temporary worktrees or `wt` for parallel refactors rather than editing the same checkout concurrently.
