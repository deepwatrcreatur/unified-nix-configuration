# Work Item 33: Kea DHCP Lease Utilization Monitoring & Alerting

- **Status**: `ready`
- **Assigned Agent**: Unassigned
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

## Detailed Scope

1. **Kea Statistics Exporter / Control Socket Query**:
   - Query Kea DHCP4 control socket (`/run/kea/dhcp4.sock`) using `statistic-get-all` command, or deploy a lightweight `kea-exporter` / Python monitoring script.
   - Track key metrics:
     - `pkt4-ack-received` / `pkt4-nak-sent`
     - `declined-addresses`
     - `assigned-addresses`
     - `cumulative-assigned-addresses`

2. **Router Dashboard / Prometheus Integration**:
   - Integrate metrics into `router-dashboard` or Prometheus scraping.
   - Add alert rule:
     - **Warning**: Dynamic IP pool utilization > 75% OR `declined-addresses` > 5.
     - **Critical**: Dynamic IP pool utilization > 90% OR `pkt4-nak-sent` rate > 10/min.

3. **Validation Criteria**:
   - `kea-exporter` or monitoring script runs reliably without memory leaks.
   - Metrics appear cleanly in `router-dashboard` or Prometheus targets.
   - Triggering a test alert (e.g. mock declined threshold) generates a warning log in `journalctl`.
