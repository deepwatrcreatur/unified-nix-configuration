# CPU Features Aspect — Planning Document

This document captures the design for a lightweight NixOS option that exposes
per-host CPU capability flags so that modules can gate package installation
without breaking the binary cache.

**Status: Deferred.** The immediate problem (qmd/bun requiring AVX2) was solved
by making `programs.qmd.enable` opt-in per capable host. Build this when the
opt-in list becomes a maintenance burden (see trigger conditions below).

---

## Problem

Some packages require CPU instructions (AVX2, AES-NI, etc.) that are not
exposed by the default Proxmox KVM CPU type (`kvm64` / "Common KVM processor",
which only provides SSE/SSE2/SSE3). These packages build successfully on the
build machine but crash at runtime with `Illegal instruction` on under-equipped
guests.

**Observed case:** `qmd` uses `bun` to install its node modules. `bun` requires
AVX2. The router and router-backup are KVM guests with `kvm64` CPU type — they
lack AVX2, causing `bun install` to crash at build time.

**Workaround in place:** `programs.qmd.enable = lib.mkDefault false` in
`coding-agents.nix`; `workstation` and `macminim4` opt in explicitly.

---

## Community Patterns

### `nixpkgs.hostPlatform` with `gcc.arch` (idiomatic but costly)

```nix
# In a host's NixOS config:
nixpkgs.hostPlatform = {
  system = "x86_64-linux";
  gcc.arch = "skylake";   # or "haswell", "x86-64-v3", etc.
  gcc.tune = "skylake";
};
```

Setting `gcc.arch` causes nixpkgs to append `-march=skylake` to every gcc
invocation, producing different store paths from the standard build. This
**breaks binary cache compatibility** for the entire closure — all packages must
be rebuilt locally rather than fetched from attic or cache.nixos.org.

Nixpkgs exposes capability predicates derived from `gcc.arch`:

```nix
stdenv.hostPlatform.avx2Support   # bool
stdenv.hostPlatform.aesSupport    # bool
stdenv.hostPlatform.sse4_2Support # bool
# ... defined in nixpkgs/lib/systems/architectures.nix
```

These predicates are idiomatic and used by `nixos-hardware` modules and
packages inside nixpkgs. They are the right choice when you *want* CPU-tuned
builds. They are the wrong choice when you only want to *gate* package
installation.

### Custom NixOS option (no binary cache impact)

The alternative is a thin declarative option that records capability facts
without affecting build flags:

```nix
options.host.cpu.avx2 = lib.mkEnableOption "AVX2 / x86-64-v3 CPU features";
```

Modules read `config.host.cpu.avx2` to decide whether to install a package.
No derivation paths change; attic cache continues to work.

---

## Proposed Design

### 1. New module: `modules/common/cpu-features.nix`

```nix
{ lib, ... }:
{
  options.host.cpu = {
    avx2  = lib.mkEnableOption "AVX2 and x86-64-v3 feature set";
    aesNi = lib.mkEnableOption "AES-NI hardware encryption";
  };
}
```

Import this from `modules/common/` (auto-imported for all hosts). All options
default to `false` — safe for restricted KVM guests.

### 2. Den inventory integration

Add a `cpu` attrset to each host entry in `den/inventory/hosts.nix`:

```nix
workstation = {
  aspectsList = [ "nixos-base" "home-manager-users" ... ];
  cpu = { avx2 = true; aesNi = true; };
};
router = {
  aspectsList = [ "nixos-base" "home-manager-users" "router-router" ];
  # cpu omitted — both default to false
};
```

### 3. Inventory aspect or den leaf wiring

The inventory `cpu` values must be wired into `config.host.cpu.*`. Two options:

**Option A — Per-host den leaf (explicit):**

```nix
# den/hosts/workstation/default.nix
{ ... }: {
  imports = [ (mkInventoryHostModule { name = "workstation"; }) ];
  host.cpu.avx2  = true;
  host.cpu.aesNi = true;
}
```

**Option B — Inventory-driven aspect (DRY):**

Create `den/aspects/cpu-features.nix` that reads the inventory entry and sets
`config.host.cpu.*` automatically. This follows the existing pattern where
aspects receive host-specific arguments from `mkHostModule`.

Option B is cleaner but requires the aspect to receive the inventory `cpu`
attrset — check whether the current `mkHostModule` / `mkInventoryHostModule`
plumbing can pass arbitrary inventory fields through before choosing this path.

### 4. Module usage

```nix
# modules/home-manager/common/coding-agents.nix
programs.qmd.enable = lib.mkDefault config.host.cpu.avx2;
```

Any future module that installs an AVX2-dependent package follows the same
pattern, with no per-host configuration required.

---

## CPU Type Reference

| Proxmox CPU type | AVX2 | AES-NI | Notes |
|---|---|---|---|
| `kvm64` (default) | No | No | SSE/SSE2/SSE3 only |
| `host` (i7-6770 / Skylake) | Yes | Yes | Full host passthrough |
| `Haswell` (named model) | Yes | Yes | Portable across Haswell+ hosts |
| `Skylake-Client` | Yes | Yes | Portable across Skylake+ hosts |
| `aarch64` (Apple M-series) | N/A | Yes | ARM; bun AVX2 issue does not apply |

Hosts currently running `cpu: host`:
- `workstation` (physical; always had native CPU)
- `router` — upgraded 2026-04-06 from `kvm64` to `host` (i7-6770 / Skylake)

Hosts still on `kvm64` or equivalent:
- `router-backup`, `homeserver`, `attic-cache`, `authentik-host`,
  `nixos-lxc`, `inference-vm`, `rustdesk`, and others

---

## Trigger Conditions

Build this when **two or more** of the following are true:

- A second package beyond `qmd` requires an explicit per-host enable/disable
  due to CPU capability constraints.
- The opt-in host list for any single package grows beyond four entries.
- A new host is added and the developer has to remember to check the capability
  list for every relevant package.
- A package is accidentally enabled on a limited-CPU host and causes a runtime
  failure that reaches production.

---

## Implementation Checklist

When the time comes:

- [ ] Create `modules/common/cpu-features.nix` with `host.cpu.avx2` and
      `host.cpu.aesNi` options
- [ ] Decide Option A vs Option B for wiring inventory → NixOS option
- [ ] Set `host.cpu.avx2 = true` for `workstation` and (via Home Manager)
      `macminim4`; leave all other hosts at default `false`
- [ ] Replace `programs.qmd.enable = true` in `workstation` and `macminim4`
      host overlays with the module-driven default
- [ ] Audit `coding-agents.nix` and other modules for any other packages
      that should be gated similarly
- [ ] Run `module-loading-eval` CI check and rebuild router to confirm it no
      longer sees the qmd derivations
- [ ] Update this document to `Status: Done` and record the final approach
