# Router iVentoy Evaluation

This note evaluates whether iVentoy should be the near-term answer for PXE boot
in this homelab router stack.

## Recommendation

Do not make iVentoy the first implementation target.

Keep it as a later optional serving layer that can sit behind a generic PXE
configuration model if a more operator-friendly ISO boot workflow is still
wanted after basic PXE plumbing exists.

## Why

### It solves a real problem

Official iVentoy docs describe a straightforward PXE workflow for booting ISO
images directly, with support for BIOS and multiple UEFI modes, and the project
can run alongside a third-party DHCP server.

That makes it genuinely attractive for:

- ad hoc installer booting
- testing multiple ISOs without unpacking them
- mixed Windows/Linux install workflows

### But it is the wrong first dependency for this repo

The current official project information also makes several tradeoffs clear:

- iVentoy is only partly open source; the upstream GitHub repo explicitly says
  it contains only the open-source part of the project
- the official FAQ says Secure Boot is not supported
- the free edition is capped at 20 clients and does not include ARM64 client
  support
- the documented Linux workflow is centered on unpacking the upstream bundle and
  starting it via `sudo bash iventoy.sh start`, with state saved through its web
  UI

Those are not fatal flaws for a lab tool, but they are poor characteristics for
the first repo-managed, Nix-shaped PXE feature.

## Fit Against This Repo's Architecture

The architecture established in
[`docs/router-pxe-boot-architecture.md`](./router-pxe-boot-architecture.md)
puts the reusable PXE option model in `nix-router-optimized` and keeps host
policy in this repo.

iVentoy does not change that boundary well because it is primarily a combined
boot artifact/menu service, not the DHCP option model itself.

If adopted, it should sit behind the generic model:

1. the router advertises boot server and boot filename values declaratively
2. a serving layer provides the actual loader and ISO/menu workflow
3. iVentoy is one possible serving layer, not the schema owner

## DHCP Integration Risk

The official third-party DHCP documentation is workable but highlights why
iVentoy should not define the first implementation slice.

When iVentoy is not the DHCP server:

- the external DHCP server must support `next-server` and `bootfile`
- if iVentoy and the DHCP server are on different VLANs, mixed BIOS/UEFI
  clients may require DHCP logic that selects different bootfiles dynamically
  based on client architecture

That is more complexity than the first PR should take on.

For this homelab, the clean first step is narrower:

- support one UEFI-first boot path
- advertise one boot target declaratively
- keep BIOS branching and richer boot-menu logic for later

## Packaging And Operations View

iVentoy still has potential value later, especially if the goal becomes
"operator-friendly ISO boot appliance" rather than just "router can advertise a
PXE target."

Reasons it may be worth revisiting later:

- direct ISO booting is convenient
- HTTP access to ISO contents could simplify some unattended install workflows
- it can coexist with a third-party DHCP server

Reasons not to choose it first:

- it would introduce a partly closed-source dependency before the repo even has
  a stable generic PXE model
- secure-boot-disabled boot paths are a poor default assumption
- its service/runtime model is less naturally Nix-native than a small
  declarative DHCP-plus-file-serving slice

## Decision

Decision: defer iVentoy as an optional later integration.

Use the next implementation task to build the generic PXE configuration surface
first. If later testing shows that ad hoc ISO booting is a recurring operator
need, add a separate repo work item for packaging or wrapping iVentoy as an
optional service layer.

## Sources

- iVentoy main page: <https://www.iventoy.com/en/index.html>
- iVentoy get started: <https://www.iventoy.com/en/doc_start.html>
- iVentoy third-party DHCP integration: <https://www.iventoy.com/en/doc_ext_dhcp.html>
- iVentoy editions: <https://www.iventoy.com/en/doc_edition.html>
- iVentoy FAQ: <https://www.iventoy.com/en/faq.html>
- Official open-source-part notice: <https://github.com/ventoy/PXE>
