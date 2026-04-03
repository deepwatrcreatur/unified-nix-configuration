# 02 API And Proxmox Wrapper Candidates

Status: `ready`

Suggested branch: `feat/tooling-api-proxmox-wrappers`

## Goal

Decide whether this repo should expose dedicated secret-aware wrappers for API
calls and Proxmox operations, and implement only the ones that clearly improve
operator ergonomics.

## Scope

- evaluate a dedicated API helper wrapper such as `curl-api` or `xh-api`
- evaluate whether there is a stable Proxmox helper command worth wrapping
- prefer dedicated helper commands over overriding raw `curl`
- make the secret sources and intended usage clear in docs or comments

## Non-Goals

- replacing raw `curl` globally
- wrapping every command that could theoretically use a token

## Validation

- chosen helper commands evaluate cleanly on hosts that import the relevant
  modules
- helpers are clearly documented as intentional wrappers, not silent
  replacements for unrelated tools
