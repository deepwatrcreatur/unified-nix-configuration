# 42 — Apple DNS Privacy Compatibility Review

Status: `ready`
Suggested branch: `docs/apple-dns-privacy-compat`
Priority: `medium`

## Goal

Document how the router’s DNS and Wi-Fi behavior interacts with Apple client
privacy warnings so flake users can distinguish harmless client-side messages
from real router misconfiguration.

## Why This Matters

During recovery validation, an iPad reported a Wi-Fi privacy warning. The
specific warning was about `Private Wi-Fi Address`, which is not a router bug,
but similar Apple warnings can also reflect DNS privacy limitations.

We should capture the difference explicitly:

- `Private Wi-Fi Address` warning: client preference / SSID policy issue
- encrypted DNS blocked/unavailable warning: possible router feature gap

## Tasks

- document common Apple Wi-Fi privacy warnings relevant to router operators
- map each warning to:
  - client-side preference
  - access-point/Wi-Fi behavior
  - router DNS behavior
- note what the current router does today:
  - plain DNS on `:53`
  - no first-class client encrypted DNS path
- link to item 41 for actual encrypted-DNS implementation work

## Constraints

- keep this item documentation-only
- avoid speculative promises about Apple discovery protocols without validation

## Validation

- router operators can look up an Apple warning and quickly tell whether it is:
  - safe to ignore
  - an AP/Wi-Fi issue
  - or a router DNS feature gap

