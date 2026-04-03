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
