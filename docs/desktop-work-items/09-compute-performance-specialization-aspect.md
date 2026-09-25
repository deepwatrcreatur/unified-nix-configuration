# 09 Compute-Performance Specialization Aspect

Status: `done`
Suggested branch: `feat/aspect-compute-performance`
Priority: `medium`

## Goal

Add a `compute-performance` bootloader specialization aspect (`den/aspects/compute-performance.nix`) that reconfigures the kernel, CPU governors, and memory management for heavy local LLM inference, machine learning, and multi-core compilation.

## Why

Desktop systems (like `phoenix` with AMD Ryzen and dedicated GPUs) balance energy efficiency, sleep states, and fan noise during general everyday use. However, running intensive model fine-tuning, large local LLMs (Ollama / vLLM), or massive NixOS builds benefits from pinning governors to maximum performance, configuring transparent hugepages, and optimizing systemd task scheduler weights.

## Scope

1. Create `modules/nixos/specializations/compute-performance.nix`:
   - Specialization tag: `system.nixos.tags = [ "compute-perf" ];`.
   - CPU scaling governor: locks all cores to `performance` (`power-profiles-daemon` or `cpufreq` policy).
   - Memory tuning:
     - Enables Transparent Hugepages: `kernel.sysctl."vm.nr_hugepages"` or `boot.kernelParams = [ "transparent_hugepage=always" ];`.
     - Sets swap aggressiveness appropriate for high-memory compute (`vm.swappiness = 10`).
   - Disables PCIe power-saving link states (`pcie_aspm=off`).
   - Increases systemd slice resource allocations and process nice limits for compilation and AI workloads.
2. Create `den/aspects/compute-performance.nix` and register in `den/aspects/default.nix`.
3. Provide option `options.myModules.specializations.computePerformance.enable` (default `false`).
4. Wire as an opt-in aspect available for `phoenix` and inference nodes.

## Validation

- `nix eval .#nixosConfigurations.phoenix.config.system.build.toplevel.drvPath` evaluates cleanly.
- When enabled on `phoenix`, `specialisation.compute-performance.configuration.system.nixos.tags` evaluates to `[ "compute-perf" ]`.
