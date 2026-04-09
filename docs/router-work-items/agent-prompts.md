# Router Agent Prompts

These prompts are designed for parallel agents working in separate worktrees.

Use one prompt per agent. Each prompt maps to one work-item file in this
folder. The prompts assume:

- the repo is `unified-nix-configuration`
- the router is now recoverable on management IP
- the current baseline model must be preserved:
  - shared production router identity
  - distinct management identities
  - standby/dev use with production NICs unplugged must remain supported

Before using any prompt, read:

- [`START-HERE.md`](./START-HERE.md)

Important:

- task-file status is authoritative
- existing branches/worktrees are only a hint
- if a suggested branch exists but there is no clear evidence of active
  ownership, treat it as stale rather than automatically skipping the task

## Prompt 1: Recovery Invariants

Work on [`01-router-recovery-invariants.md`](./01-router-recovery-invariants.md).

Create a branch named `fix/router-recovery-invariants`.

Task:
- lock in the recent router recovery fixes as explicit invariants
- add checks or assertions for the most important ones
- document the intended standby/dev behavior clearly

Important constraints:
- do not change production LAN identity
- do not change the router-backup management-IP model
- do not mix in unrelated refactors

Validation target:
- `nix build .#nixosConfigurations.router.config.system.build.toplevel`
- `nix build .#nixosConfigurations.router-backup.config.system.build.toplevel`

Deliver:
- commit(s) on the branch
- brief summary of invariants added
- any remaining gaps that need a second PR

## Prompt 2: Stable Interface Matching

Work on [`02-stable-interface-matching.md`](./02-stable-interface-matching.md).

Create a branch named `refactor/router-stable-interface-matching`.

Task:
- remove dependence on fragile `enp6s16` / `enp6s17` naming for the router role
- inspect current support in local code and `nix-router-optimized`
- choose the cleanest stable matching approach available

Known live details:
- router passthrough NIC 1:
  - path `pci-0000:06:10.0`
  - MAC `02:76:c6:01:2a:af`
- router passthrough NIC 2:
  - path `pci-0000:06:11.0`
  - MAC `02:76:c6:01:2a:b0`
- management NIC is virtio

Important constraints:
- preserve shared production identity
- do not mix this with VLAN or VPN work

Validation target:
- local router/router-backup eval or build
- confirm generated config no longer relies purely on kernel naming

Deliver:
- branch commit(s)
- summary of matching approach chosen and why

## Prompt 3: Management Plane Independence

Work on [`03-management-plane-independence.md`](./03-management-plane-independence.md).

Create a branch named `feat/router-management-plane-independence`.

Task:
- make management-plane availability a first-class invariant in code and docs
- audit router-local services and dashboard behavior for LAN-first assumptions

Important constraints:
- `router` management IP is `192.168.100.100`
- `router-backup` management IP is `192.168.100.99`
- do not make management depend on WAN or LAN success

Validation target:
- router/router-backup build
- dashboard links and binds remain management-usable

Deliver:
- branch commit(s)
- summary of what was made management-first

## Prompt 4: Service Dependency Cleanup

Work on [`04-service-dependency-cleanup.md`](./04-service-dependency-cleanup.md).

Create a branch named `refactor/router-service-dependencies`.

Task:
- audit remaining router-local services that wait broadly on `10.10.10.1`
- replace over-broad waiting with clearer dependency logic where possible

Services of interest:
- Prometheus
- Grafana
- Netdata
- router-dashboard
- any other router-local service with pre-start polling

Important constraints:
- do not hide degraded state
- do not weaken true LAN-dependent behavior for production traffic

Validation target:
- router build
- service startup logic is clearer and less fragile

Deliver:
- branch commit(s)
- list of services changed and why

## Prompt 5: Router Health Model

Work on [`05-router-health-model.md`](./05-router-health-model.md).

Create a branch named `feat/router-health-model`.

Task:
- add an explicit health model for router interface state and major recovery
  surfaces
- prefer a dashboard/operator-facing result, not just a code refactor

Health dimensions:
- management IP present
- LAN IP present
- WAN carrier/address known
- monitoring availability

Important constraints:
- do not collapse all health into a single bit
- keep the output easy for an operator to understand quickly

Validation target:
- router build
- clear degraded state visible in the dashboard or status outputs

Deliver:
- branch commit(s)
- short note on the chosen health representation

## Prompt 6: Boot And Recovery Hardening

Work on [`06-boot-and-recovery-hardening.md`](./06-boot-and-recovery-hardening.md).

Create a branch named `refactor/router-boot-recovery`.

Task:
- harden and document router recovery paths for the Proxmox VM model
- verify the current serial and guest-agent assumptions are actually enforced

Known expectations:
- Proxmox VM has serial console enabled
- router role includes serial console kernel param
- qemu guest agent is enabled

Important constraints:
- keep this focused on recovery plumbing and documentation
- do not mix in interface-model refactors

Validation target:
- router/router-backup build
- doc accuracy against actual VM expectations

Deliver:
- branch commit(s)
- updated recovery notes

## Prompt 7: Observability And Flow Logging

Work on [`07-observability-and-flow-logging.md`](./07-observability-and-flow-logging.md).

Create a branch named `feat/router-flow-logging`.

Task:
- evaluate and, if appropriate, prototype useful observability ideas borrowed
  from `joshpearce/nix-router`
- especially `ulogd` and `vector` as optional modules

Important constraints:
- this is optional capability work
- do not destabilize the current router role
- prefer modular/opt-in integration

Validation target:
- router build
- observability feature can stay disabled by default

Deliver:
- branch commit(s)
- explicit summary of what was borrowed and why

## Prompt 8: VLANs And VPN Policy Routing

Work on [`08-vlans-and-vpn-policy-routing.md`](./08-vlans-and-vpn-policy-routing.md).

Create a branch named `feat/router-vlans-and-vpn-routing`.

Task:
- design and, if feasible, begin implementing first-class VLAN and VPN
  policy-routing support
- optimize for the real use case:
  - per-SSID / per-VLAN VPN egress
  - per-device VPN routing

Important constraints:
- do not start with per-domain geo-routing hacks
- keep management-plane independence intact

Validation target:
- at least one isolated routing path can be modeled without affecting primary
  LAN

Deliver:
- branch commit(s)
- note any upstream `nix-router-optimized` work that should be split out

## Prompt 9: Kea And Technitium Architecture

Work on [`09-kea-technitium-architecture.md`](./09-kea-technitium-architecture.md).

Create a branch named `docs/router-kea-technitium-architecture`.

Task:
- design the target architecture for Kea DHCP + Technitium DNS in this homelab
- make the migration stages explicit
- distinguish DHCP HA from gateway failover

Important constraints:
- do not implement Kea yet
- do not pretend DHCP HA alone solves shared-LAN router failover
- optimize for the real homelab use case, not generic enterprise routing

Deliver:
- branch commit(s)
- a concise architecture note with migration stages and open questions

## Prompt 10: Router Kea Module Roadmap

Work on [`10-router-kea-module-roadmap.md`](./10-router-kea-module-roadmap.md).

Create a branch named `docs/router-kea-module-roadmap`.

Task:
- define the module/API shape for optional Kea support in `nix-router-optimized`
- separate what belongs upstream from what should stay repo-local at first

Important constraints:
- Kea must remain optional
- do not make Technitium-specific assumptions the upstream module cannot support
- do not implement the module in this task

Deliver:
- branch commit(s)
- proposed module boundaries and option schema ideas

## Prompt 11: Internal Router Admin Hostnames

Work on [`11-internal-admin-hostnames.md`](./11-internal-admin-hostnames.md).

Create a branch named `feat/router-internal-admin-hostnames`.

Task:
- design or implement internal-only admin hostnames such as
  `technitium.deepwatercreature.com` and `kea.deepwatercreature.com`
- keep them out of public DDNS/public ingress

Important constraints:
- preserve raw management-IP recovery access
- do not leak internal admin names into Cloudflare/public DNS

Deliver:
- branch commit(s)
- summary of inventory/Caddy/DNS changes required

## Prompt 12: VPN Module Hardening And Tests

Work on [`12-vpn-module-hardening-and-tests.md`](./12-vpn-module-hardening-and-tests.md).

Create a branch named `docs/router-vpn-module-hardening`.

Task:
- turn the recent VPN wrapper review feedback into explicit upstream tasks
- rank testing, guardrails, docs, and helper-refactor work

Important constraints:
- split into PR-sized work items
- do not lump all VPN follow-ups into one change

Deliver:
- branch commit(s)
- a ranked upstream task breakdown
## Prompt 13: VyOS Pattern Study

Work on [`13-vyos-pattern-study.md`](./13-vyos-pattern-study.md).

Create a branch named `docs/router-vyos-pattern-study`.

Task:
- study the VyOS codebase and docs for router-architecture ideas worth
  borrowing into this repo
- produce a concise recommendation, not a platform migration

Focus areas:
- interface role modeling
- management/control-plane separation
- firewall/NAT/policy-routing structure
- diagnostics and operator workflow

Important constraints:
- do not turn this into "rewrite the router like VyOS"
- do not add enterprise-only complexity without a homelab payoff
- prefer concrete follow-up ideas over broad theory

Deliver:
- branch commit(s)
- short note listing patterns to borrow, defer, and reject
## Prompt 14: Upstream Hotfix Pinning Policy

Work on [`14-upstream-hotfix-pinning-policy.md`](./14-upstream-hotfix-pinning-policy.md).

Create a branch named `docs/router-hotfix-pinning-policy`.

Task:
- document a repeatable policy for temporarily consuming upstream router/infra
  hotfixes and then returning to stable refs
- optimize for recent real examples like the Technitium NTP sync fix

Important constraints:
- keep it short and operational
- focus on prod-critical inputs, not every flake input in the repo

Deliver:
- branch commit(s)
- concise policy/checklist docs

## Prompt 15: Management Plane Smoke Validation

Work on [`15-management-plane-smoke-validation.md`](./15-management-plane-smoke-validation.md).

Create a branch named `feat/router-management-plane-smoke-validation`.

Task:
- add one repeatable smoke-validation path for management-plane recovery
- back the existing manual ops guidance with a lightweight automated check

Important constraints:
- do not require a full VM test harness in the first version
- keep scope to the management-plane model, not all router behavior

Deliver:
- branch commit(s)
- summary of what the smoke check proves and what it does not

## Prompt 18: Operational Diagnostics CLI

Work on [`18-router-diag-cli.md`](./18-router-diag-cli.md).

Create a branch named `feat/router-diag-cli`.

Task:
- create a lightweight `router-diag` CLI tool for terminal-based diagnostics
- implement subcommands for interfaces, firewall, VPN, and health status

Important constraints:
- keep it read-only (diagnostics only)
- prefer simple bash or python with minimal dependencies
- surface the explicit health checks from Task 05

Validation target:
- `router-diag show health` returns accurate results
- tool is available in the default system path on the router

Deliver:
- branch commit(s)
- summary of the tool's capabilities and usage

## Prompt 23: Ulogd Plugin Mismatch Repair

Work on [`23-ulogd-plugin-mismatch-repair.md`](./23-ulogd-plugin-mismatch-repair.md).

Create a branch named `fix/router-ulogd-plugin-mismatch`.

Task:
- repair the current `ulogd` startup failure on router/router-backup
- align the generated config with the plugin set actually shipped by the
  packaged `ulogd`

Important constraints:
- keep this as a narrow runtime repair
- do not redesign all router observability in the same PR
- validate against the real packaged plugin files, not assumptions from older
  configs or upstream examples

Validation target:
- router/router-backup build
- `ulogd.service` starts successfully after switch

Deliver:
- branch commit(s)
- short note listing which plugins were expected, which were actually present,
  and what changed

## Prompt 24: Ulogd Package Vs Design Alignment

Work on [`24-ulogd-package-vs-design-alignment.md`](./24-ulogd-package-vs-design-alignment.md).

Create a branch named `docs/router-ulogd-design-alignment`.

Task:
- document the supported `ulogd` stack for this repo and decide how tightly the
  router design should depend on packaged plugin availability
- add comments/docs so future agents stop reintroducing unsupported plugin
  references casually

Important constraints:
- keep this focused on design clarity and follow-up hardening
- do not turn it into a full observability platform redesign

Validation target:
- docs/comments make the supported flow-logging path clear
- future follow-up work can distinguish package mismatch from design drift

Deliver:
- branch commit(s)
- concise summary of the chosen support boundary

## Prompt 25: Technitium DHCP Sync Hardening

Work on [`25-technitium-dhcp-sync-hardening.md`](./25-technitium-dhcp-sync-hardening.md).

Create a branch named `fix/router-technitium-dhcp-sync-hardening`.

Task:
- harden the `router-technitium` DHCP sync behavior in
  `nix-router-optimized`
- make convergence and failure semantics explicit for scopes and reservations

Important constraints:
- treat this as upstream-quality module work
- keep dashboard and host-local router changes out of the branch
- optimize for a PR and bot review, not an unreviewed direct merge

Deliver:
- branch commit(s)
- PR-ready summary of what convergence cases were handled

## Prompt 26: Router Dashboard Runtime Repair

Work on [`26-router-dashboard-runtime-repair.md`](./26-router-dashboard-runtime-repair.md).

Create a branch named `fix/router-dashboard-runtime-repair`.

Task:
- repair the current router-dashboard runtime regressions around interface
  cards, fail2ban status, and Caddy token visibility

Important constraints:
- keep the fix narrow and operational
- split upstream-vs-host-local changes cleanly if both repos are touched
- do not mix Technitium DHCP sync logic into this branch

Deliver:
- branch commit(s)
- short live-router verification note

## Prompt 27: Router Post-Cutover Validation

Work on [`27-router-post-cutover-validation.md`](./27-router-post-cutover-validation.md).

Create a branch named `ops/router-post-cutover-validation`.

Task:
- define and, if useful, lightly automate the post-cutover checks that catch
  DHCP-reservation-dependent failures such as `attic-cache` landing on the
  wrong address

Important constraints:
- keep this lightweight and operator-facing
- do not turn it into a full integration test harness
- document blocking vs advisory checks clearly

Deliver:
- branch commit(s)
- concise validation checklist and any helper command/script additions

## Prompt 28: DHCP Provider Pluggable Observability

Work on [`28-dhcp-provider-pluggable-observability.md`](./28-dhcp-provider-pluggable-observability.md).

Create a branch named `design/router-dhcp-provider-observability`.

Task:
- design how router-dashboard and related diagnostics should expose DHCP leases
  and status when DHCP may come from Technitium or Kea

Important constraints:
- keep this as architecture/design work
- do not implement Kea in this task
- avoid cementing Technitium-specific assumptions into the future boundary

Deliver:
- branch commit(s)
- concise design note with follow-up implementation slices

## Prompt 29: Router Caddy Source Drift Repair

Work on [`29-router-caddy-source-drift-repair.md`](./29-router-caddy-source-drift-repair.md).

Create a branch named `fix/router-caddy-source-drift`.

Task:
- repair the current router rebuild failure caused by the Caddy-with-plugins
  fixed-output hash mismatch
- keep the change narrow and explain the source of the drift

Important constraints:
- do not mix in unrelated reverse-proxy or router refactors
- treat this as an immediate rebuild blocker
- prefer a deterministic pinned fix over a speculative workaround

Validation target:
- router build progresses past the current Caddy derivation failure

Deliver:
- branch commit(s)
- short note on what drifted and what was pinned or regenerated
