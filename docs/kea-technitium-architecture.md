# Kea and Technitium Architecture

This document outlines the target architecture for moving DHCP services from Technitium to Kea, while maintaining Technitium as the primary DNS authority and admin UI.

## Goal

The objective is to leverage Kea's robust DHCP features (including High Availability) while continuing to use Technitium for its excellent DNS management and user interface.

## Recommended Architecture

### 1. DHCP: Kea (kea-dhcp4)
- **Role**: Primary DHCPv4 server.
- **Benefits**: Modular, high-performance, supports High Availability (HA) natively, and provides better integration with external tools via hooks.
- **Config**: Defined declaratively in NixOS using `services.kea.dhcp4`.

### 2. DDNS: Kea D2 (kea-dhcp-ddns)
- **Role**: Intermediary between Kea DHCP and Technitium DNS.
- **Function**: Receives lease information from `kea-dhcp4` and sends RFC2136 DNS Update packets to Technitium.
- **Config**: `services.kea.dhcp-ddns`.

### 3. DNS: Technitium
- **Role**: Authoritative DNS server for the local domain (`deepwatercreature.com`).
- **Integration**: Must have "Allow DNS Updates" enabled for the relevant zones, restricted by TSIG or IP allowlist.
- **UI**: Remains the primary tool for manual DNS record management.

## Responsibility Split

| Feature | Component | Notes |
| :--- | :--- | :--- |
| IP Assignment | Kea DHCP4 | Declarative pools and reservations |
| Hostname -> IP | Kea D2 -> Technitium | Automatic DDNS updates |
| DNS Authority | Technitium | Serves records to clients |
| Admin UI (DNS) | Technitium | Web dashboard for DNS logs/zones |
| Admin UI (DHCP) | N/A (or Stork) | Kea is currently CLI/Nix-first here |

## Migration Stages

### Stage 1: Parallel Operation (Shadowing)
- Install Kea but keep DHCP disabled or on a separate VLAN.
- Verify Kea can update Technitium via RFC2136 using a test zone.

### Stage 2: Migration of Reservations
- Port declarative `services.router-technitium.dhcpReservations` from the current sync script to Kea's `reservations` format.
- This ensures consistency during the cutover.

### Stage 3: Cutover
- Disable DHCP in Technitium.
- Enable DHCP in Kea.
- Monitor lease pick-up and DDNS registration in Technitium logs.

## Hard Blockers / Unknowns

- **Technitium RFC2136 Support**: While Technitium supports standard DNS updates, the exact TSIG configuration compatibility with Kea D2 needs validation.
- **Kea HA Complexity**: Implementing HA between `router` and `router-backup` requires a shared backend (e.g., PostgreSQL) or Kea's native HA hook. Postgres is likely overkill; native HA hook is preferred.

## DHCP HA vs. Gateway Failover

It is critical to distinguish between these two:
- **DHCP HA**: Ensures clients can always get an IP address even if one router is down.
- **Gateway Failover**: Ensures that the IP address the clients *already have* as their gateway (`10.10.10.1`) remains functional.

Kea HA addresses the first. VRRP or manual cutover (as currently documented in `docs/ops.md`) addresses the second.

## Kea Memfile Lease Resilience & Declined State Recovery

When using Kea's `memfile` database, lease state is persisted across service restarts in `/var/lib/private/kea/dhcp4.leases` and Kea's Lease File Cleanup (LFC) backup files (`dhcp4.leases.2`).

### Failure Mode: Stale `DECLINED` Lease Locks
If an IP address is marked as `DECLINED` (e.g. due to client ARP probe conflicts or legacy AP lease loops) and persists in Kea's LFC backup files:
1. Kea re-imports the `DECLINED` leases on startup.
2. Subsequent requests for those IPs trigger `ALLOC_ENGINE_V4_DISCOVER_ADDRESS_CONFLICT`.
3. Kea executes 5,800+ allocation retries per packet and issues `DHCPNAK` packets, causing client reconnect loops.

### Declarative Protections in NixOS Configuration

1. **Pre-Start Lease Sanitization (`router-kea-ensure-state`)**:
   Runs via systemd `ExecStartPre` before `kea-dhcp4-server` initializes. Automatically inspects `dhcp4.leases` and `dhcp4.leases.2`, strips out any `DECLINED` lines (`state = 1`), and cleans up stale `.incompatible.*` backups older than 24 hours.

2. **Automatic Expired Lease Processing (`expired-leases-processing`)**:
   Configured in `services.kea.dhcp4.settings` to periodically reclaim and flush expired leases every 10–25 seconds:
   ```nix
   services.kea.dhcp4.settings = {
     expired-leases-processing = {
       reclaim-timer-wait-time = 10;
       flush-reclaimed-timer-wait-time = 25;
       hold-reclaimed-time = 3600;
       max-reclaim-leases = 100;
       max-reclaim-time = 250;
     };
   };
   ```

### Optionality & Governance
- **Default Policy**: Enabled by default (`ownLanServices = true`) on the production router to prevent DHCP lockouts out-of-the-box.
- **Overridability**: Exposed declaratively via `services.kea.dhcp4.settings` so non-production nodes or custom test fixtures can adjust timer windows (or disable pre-start purging for forensic analysis) if required.

## Future Direction

Once Kea is stable, we can explore:
- **DHCPv6**: Using `kea-dhcp6` for better IPv6 management.
- **Kea Stork**: A dashboard for monitoring Kea clusters.
- **Shared Lease Database**: Moving leases to a lightweight database (like SQLite or a small PG instance) to survive router reboots without losing lease state.
