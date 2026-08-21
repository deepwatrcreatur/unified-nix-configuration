# Work Item 33: Kea DHCP Lease Utilization Monitoring & Alerting

- **Status**: `done`
- **Assigned Agent**: Antigravity
- **Target System**: `router` (`10.10.10.1`)

## Background

Following the recent Kea DHCP pool exhaustion incident caused by device ARP conflict loops and stale `DECLINED` lease re-imports, we hardened the core daemon using:
1. `router-kea-ensure-state`: Column-aware startup sanitization via `gawk -F, 'NR==1 || $10 != "1"'`.
2. `decline-probation-period = 300`: 5-minute runtime probation for `DECLINED` leases.
3. `match-client-id = false` & `host-reservation-identifiers = [ "hw-address" ]`: Strict physical MAC tracking.
4. `valid-lifetime = 14400` & `hold-reclaimed-time = 300`: 4-hour lease recycling and 5-minute reclaimed hold windows.

However, as identified in the agent roundtable discussion (Codex, DeepSeek, Claude), we need **proactive runtime observability** to alert operators *before* IP pool pressure or NAK storms impact LAN clients.

## Objective

Expose Kea DHCP metrics (lease utilization, `DECLINED` address count, allocation retries, and `DHCPNAK` rates) to Prometheus / `router-dashboard`, and configure alert thresholds in Grafana / systemd notifications.

## Implementation Details

1. **Kea Exporter Script (`modules/router-kea/router-kea-exporter.py`)**:
   - Queries Kea DHCP4 control socket (`/run/kea/dhcp4.sock`) using `statistic-get-all` UNIX socket payload.
   - Falls back gracefully to parsing `/var/lib/kea/dhcp4.leases` when socket is starting or unavailable.
   - Tracks metrics:
     - `kea_dhcp4_assigned_addresses`
     - `kea_dhcp4_declined_addresses`
     - `kea_dhcp4_cumulative_assigned_addresses`
     - `kea_dhcp4_pkt4_ack_received`
     - `kea_dhcp4_pkt4_nak_sent`
     - `kea_dhcp4_total_addresses`
     - `kea_dhcp4_pool_utilization_percent`
   - Exports HTTP Prometheus endpoint on port `9547` (`/metrics`).
   - Writes state snapshots to `/run/router/kea-metrics.json` and `/run/router/dhcp-status.json`.
   - Logs warning/critical entries directly to `journalctl` when thresholds are breached.

2. **Systemd Service Integration (`modules/router-kea.nix`)**:
   - Added `services.router-kea.exporter` options (`enable` = true, `port` = 9547).
   - Configured `systemd.services.router-kea-exporter` to run automatically after `kea-dhcp4-server.service`.

3. **Prometheus Scrape Target & Alert Rules (`modules/monitoring.nix`)**:
   - Added `kea` scrape target (`localhost:9547`) to `services.prometheus.scrapeConfigs`.
   - Added rule alerts under `services.prometheus.rules`:
     - `KeaDhcpPoolUtilizationWarning`: Pool utilization > 75% (warning).
     - `KeaDhcpPoolUtilizationCritical`: Pool utilization > 90% (critical).
     - `KeaDhcpDeclinedAddressesWarning`: Declined address count > 5 (warning).
     - `KeaDhcpNakRateCritical`: NAK rate > 10/min (critical).

4. **Router Dashboard Integration (`router-dashboard`)**:
   - Updated `server.py` (`send_kea_dhcp_leases`) to supply `poolUtilization`, `declinedAddresses`, `totalAddresses`, `assignedAddresses`, `nakSentCount`, and `ackReceivedCount` in `/api/dhcp/leases`.
   - Updated `dhcp-widget.js` to render pool utilization `%` and highlighted `⚠️ X declined` badges when present.

5. **Evaluation & Verification**:
   - Added `router-kea-monitoring-eval` in `tests/router-kea-eval.nix`.
   - Verified NixOS configuration evaluation for `router` host configuration via `nix eval`.
