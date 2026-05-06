# Router Post-Cutover Validation

Status: `done`
Suggested branch: `ops/router-post-cutover-validation`
Priority: `medium`

## Goal

Capture and validate the concrete recovery checks that should be run after a
 router cutover or DHCP repair, with special attention to services that depend
on reserved leases.

## Why This Matters

The recent router swap left several second-order failures that were easy to
miss while focusing on basic Internet access:

- `attic-cache` was unreachable by name/IP expectations because it took a
  dynamic lease instead of its reserved address
- some Cisco APs kept their reserved leases but did not actually return at L2
  after router / HA churn
- remote build flows implicitly depended on that address being correct
- dashboard/cutover validation did not make these dependent failures obvious

The router needs a lightweight post-cutover validation path that catches these
problems quickly.

## Tasks

- define a short post-cutover checklist for:
  - DHCP scope health
  - reserved-lease convergence
  - critical static-lease-dependent services such as `attic-cache`
  - AP recovery state, especially distinguishing:
    - lease exists
    - host answers ARP
    - host answers ICMP / HTTP
    - manual AP power cycle is required
  - dashboard reachability on the management plane
- add or refine one repeatable validation command/script path where useful
- document which checks are blocking for “router is healthy enough” and which
  are advisory
- note any follow-up work that should become its own queue item instead of
  being bundled here

## Constraints

- keep this focused on post-cutover operational validation, not a full router
  test harness
- do not redesign the entire management-plane smoke validation model
- keep any automation lightweight and operator-friendly

## Validation

- a human or agent can run the documented checks after a router switch and
  quickly identify whether reserved-lease-dependent services have recovered
- the check path explicitly catches the `attic-cache` wrong-IP scenario

## Deliverable

- branch commit(s)
- concise docs and/or helper scripts for post-cutover validation

## AP-Specific Checklist

When the router path has churned but Wi-Fi is still degraded, do not stop at
"lease exists."

1. Check whether each AP still has its intended reserved lease in Kea.
2. Check whether the router has a live neighbor entry for the AP IP/MAC.
3. If neighbor state is `FAILED` and `arping` receives no response, treat the
   AP as absent at L2 rather than as a DHCP or DNS problem.
4. If one AP recovers and others do not, do not assume a controller-wide
   failure. Treat the missing APs as per-device recovery cases.
5. If an AP answers ping or HTTP again, consider the basic network path
   restored and move up-stack.
6. If an AP keeps its lease but stays absent at L2, stop changing router DHCP
   state and move to manual recovery:
   - local power cycle
   - PoE bounce if switch capability exists
   - physical link / power verification
7. Record the result in a durable incident note, including:
   - which APs recovered automatically
   - which APs required manual intervention
   - what was ruled out on the router side
