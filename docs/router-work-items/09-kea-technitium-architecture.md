# Kea And Technitium Architecture

Status: `done`
Suggested branch: `docs/router-kea-technitium-architecture`
Priority: `high`

## Goal

Design the target architecture for using Kea as the DHCP engine while keeping
Technitium as the DNS authority and admin UI for homelab DNS.

## Why This Matters

This is the most plausible path toward:

- reliable DHCP lease registration in DNS
- future DHCP high availability between `router` and `router-backup`
- eventual support for keeping both LAN ports connected at the same time

It also avoids treating Technitium's built-in DHCP as the long-term HA path.

## Questions To Answer

- What is the cleanest split of responsibility between Kea and Technitium?
- Should Kea update Technitium via RFC2136/D2 only, or is there any reason to
  keep Technitium DHCP enabled?
- What exact pieces are required for DHCPv4 + DDNS with your current LAN model?
- What does a realistic migration path look like from Technitium DHCP to Kea?
- What remains unsolved even after DHCP HA is improved?

## Target Direction

Preferred assumption unless research disproves it:

- Kea handles DHCP
- Kea D2 handles DDNS
- Technitium remains the DNS server and DNS admin UI
- Technitium DHCP is disabled in the final target design

## Deliverable

The recommended architecture is documented in [`docs/kea-technitium-architecture.md`](../kea-technitium-architecture.md).

## Do Not

- do not start implementing Kea yet in this task
- do not claim that DHCP HA alone solves router failover
- do not drift into generic enterprise-routing design
