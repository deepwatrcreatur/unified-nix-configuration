# Router DHCP / HA / AP Incident — 2026-05-05

Status: `open follow-up`

This records the operational facts from the 2026-05-05 router rollback and AP
recovery incident so the next operator does not have to reconstruct them from
chat history.

## Summary

After rebooting into an earlier router generation to restore family Internet
service, the live system showed two overlapping failures:

1. the older HA design flaw was back in effect, with `router-backup`
   unreachable and the primary waiting to time into `PARTNER-DOWN`
2. `kea-dhcp4-server` was not merely degraded, it had failed to start because
   it could not reopen its lease state files

Once Kea state ownership was repaired and the service restarted, the primary
router resumed DHCP service locally. Cisco AP recovery remained partial: one AP
returned cleanly, two did not reappear even though their reservations and old
leases still existed.

## Exact Live Findings

Observed from `router` on 2026-05-05:

- `kea-dhcp4-server` was down after rollback because:
  - `/var/lib/private/kea` was not owned by `kea`
  - `dhcp4.leases` and `dhcp4.leases.2` were not readable/writable by the
    service user
- after repairing ownership and restarting Kea:
  - `kea-dhcp4-server` became `active`
  - it listened again on `10.10.10.2:67`
  - it transitioned `WAITING -> PARTNER-DOWN`
  - local DHCP serving was enabled again
- fresh DHCP traffic after recovery was confirmed:
  - at `2026-05-05 23:30:09` a client received lease `10.10.10.197`
  - the journal showed `DHCPREQUEST`, allocation, and `DHCPACK`
- HA remained degraded in the old-generation way:
  - heartbeat failures continued to `http://192.168.100.99:8000/`
  - `router-backup` remained unreachable

## AP-Specific Findings

Expected reserved AP addresses:

- `ap-ruqayya` -> `10.10.11.20`
- `ap-nosheen-living` -> `10.10.11.21`
- `ap-nosheen-bedroom` -> `10.10.11.22`

What Kea and the router showed after DHCP recovery:

- Kea still had historical lease entries for all three APs
- `ap-nosheen-living` (`10.10.11.21`) was back:
  - ARP reachable
  - ping succeeded
  - HTTP returned `302`
- `ap-ruqayya` (`10.10.11.20`) and `ap-nosheen-bedroom` (`10.10.11.22`) were
  still absent:
  - neighbor state `FAILED`
  - no ping
  - no fresh DHCP journal activity for those MACs after service recovery

This means the two down APs were not blocked at "Kea is refusing leases" once
DHCP was repaired. They remained absent lower in the stack, around power, link,
or AP rejoin behavior.

## Dashboard Findings

During the incident, the router dashboard misrepresented the state:

- service status API reports:
  - `technitium-dns-server` active
  - `kea-dhcp4-server` active
  - `kea-dhcp-ddns-server` active
- but the DNS and DHCP widgets still show `OFFLINE`

What was true at that point:

- the DHCP widget still depends on Technitium's DHCP API even though DHCP is
  now served by Kea
- the DNS widget depended on local Technitium API reachability and token
  wiring

Follow-up implementation changed that picture:

- the DHCP widget is now Kea-backed and no longer depends on Technitium's DHCP
  API
- on the recovered live `router`, `/api/dhcp/leases` now returns real
  Kea-backed lease data
- on the recovered live `router`, `/api/dns/stats` also returns healthy
  Technitium DNS stats again
- the remaining DNS-widget follow-up is to make failure modes explicit on hosts
  such as `router-backup` where Technitium is intentionally absent

## Emergency Fix Applied

The live, minimal repair on `router` was:

- restore ownership on:
  - `/var/lib/private/kea`
  - `dhcp4.leases`
  - `dhcp4.leases.2`
- restart `kea-dhcp4-server`

That was enough to restore local DHCP serving on the primary router.

## Operational Conclusion

Three follow-up tracks were identified:

1. harden Kea state-directory / lease-file ownership so rollback or rebuild
   does not leave DHCP dead on boot
2. fix the dashboard's data sources so it does not report DHCP/DNS as offline
   when the daemons are healthy
3. keep disruptive validation and future reproduction work on `router-backup`,
   not the family-facing `router`

Status after the initial recovery branch:

- (1) is implemented
- the DHCP half of (2) is implemented
- the DNS half of (2) is narrowed to clearer Technitium availability/token
  behavior
- (3) is now written directly into the router work queue

## Related Work Items

- [`35-ap-recovery-postmortem-gap.md`](./router-work-items/35-ap-recovery-postmortem-gap.md)
- [`36-router-backup-ha-disable-profile.md`](./router-work-items/36-router-backup-ha-disable-profile.md)
- [`37-router-backup-dhcp-regression-lab.md`](./router-work-items/37-router-backup-dhcp-regression-lab.md)
- [`38-router-dashboard-technitium-token-access.md`](./router-work-items/38-router-dashboard-technitium-token-access.md)
- [`39-router-dashboard-kea-dhcp-cutover.md`](./router-work-items/39-router-dashboard-kea-dhcp-cutover.md)
- [`40-kea-state-ownership-hardening.md`](./router-work-items/40-kea-state-ownership-hardening.md)
