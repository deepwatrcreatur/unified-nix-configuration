# Service Dependency Cleanup

Status: `ready`
Suggested branch: `refactor/router-service-dependencies`
Priority: `high`

## Goal

Remove overly broad “wait for `10.10.10.1`” behavior where a narrower or more
 accurate dependency model is possible.

## Why This Matters

Prometheus, Grafana, and Netdata looked broken largely because the production
LAN address was absent. Now that LAN can exist without carrier, this is less
fragile, but the dependency model is still too implicit.

The better model:

- services that truly need LAN should say so
- management-plane services should not block on LAN
- degraded mode should be visible rather than looking like uniform startup
  failure

## Current Relevant Areas

- router monitoring modules
- upstream `router-homelab`
- dashboard service list
- any pre-start polling scripts waiting on listen addresses

## Tasks

- Audit all remaining pre-start wait behavior for router-local services.
- Replace address polling with clearer dependencies where possible.
- Keep binding behavior explicit:
  - `0.0.0.0` when appropriate
  - specific LAN bind only when truly necessary
- Make service lists reflect intended availability in standby/dev mode.

## Validation

- local router build
- dashboard no longer shows services stuck because of a missing production
  cable alone

## Do Not

- do not weaken actual routering requirements for production traffic
- do not hide degraded state
