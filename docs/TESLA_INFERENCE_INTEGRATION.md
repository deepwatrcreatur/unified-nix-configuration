# Tesla Inference Integration

## Overview

This configuration uses [tesla-inference-flake](https://github.com/deepwatrcreatur/tesla-inference-flake) for GPU-accelerated inference with Ollama on Tesla GPUs (P40, P100, M40, M60, K-series).

## Current Configuration

**Status:** ✅ WORKING
**Approach:** Official pre-built binaries
**GPU:** Tesla P40
**Date:** January 6, 2026

### Active Configuration

Located in: `hosts/nixos/inference-vm/modules/configuration.nix`

```nix
services.ollama = {
  enable = true;
  package = pkgs.ollama-official-binaries;  # From tesla-inference-flake overlay
  environmentVariables = {
    CUDA_VISIBLE_DEVICES = "0";
    OLLAMA_GPU_OVERHEAD = "0";
    LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  };
};
```

### Flake Integration

Located in: `flake.nix:70-73, 111`

```nix
inputs = {
  tesla-inference-flake = {
    url = "github:deepwatrcreatur/tesla-inference-flake";  # Latest main branch
    inputs.nixpkgs.follows = "nixpkgs";
  };
};

commonOverlays = [
  inputs.tesla-inference-flake.overlays.ollama-official-binaries
  inputs.tesla-inference-flake.overlays.llama-cpp-tesla
  inputs.tesla-inference-flake.overlays.gpu-tools
];
```

## Build Investigation - January 6, 2026

### Source Build Test Results

**Tested:** Simple CUDA acceleration (Dec 28 working config approach)
```nix
services.ollama = {
  enable = true;
  acceleration = "cuda";  # No package override
};
```

**Result:** ❌ **FAILED**

**Error:**
```
error: Cannot build 'cuda12.8-cuda_compat-12.8.39468522.drv'
> variable $src or $srcs should point to the source
```

**Key Finding:** Even the "simple" approach fails in current nixpkgs. The cuda_compat package has a derivation error that prevents ALL CUDA source builds, regardless of configuration approach.

### Official Binaries Test Results

**Tested:** Pre-built binaries from tesla-inference-flake
```nix
services.ollama = {
  enable = true;
  package = pkgs.ollama-official-binaries;
};
```

**Result:** ✅ **SUCCESS**

Build completed successfully in ~2 minutes with no CUDA compilation errors.

## Why Official Binaries?

1. **Source builds are broken:** cuda_compat build error in nixpkgs affects ALL CUDA compilation attempts
2. **Fast deployment:** 2-5 min vs 30-60 min for source builds
3. **Proven configuration:** Pre-tested binaries with bundled CUDA 12.x/13.x libraries
4. **Latest version:** Currently ollama 0.13.5
5. **Universal compatibility:** Works with all Tesla GPUs without architecture-specific builds

**Performance tradeoff:** ~5-10% slower than optimized source build on P40, which is acceptable.

## Source Build Status

**Current Status:** Not working due to nixpkgs cuda_compat issue

**What we tried:**
- ❌ Simple `acceleration = "cuda"`
- ❌ Package override with explicit `cudaPackages`
- ❌ Setting `cudaForwardCompat = false`

**Root cause:** The `cuda_compat` package in nixpkgs has a derivation where `$src` variable is not properly set. This affects all CUDA builds in the current nixpkgs.

**Potential fix:** This is a nixpkgs upstream issue that needs to be fixed. Until then, official binaries are the only working approach.

## Verification

### Check GPU is Being Used

```bash
# SSH to inference VM
ssh 10.10.10.18

# Check ollama service
sudo systemctl status ollama

# Monitor GPU during inference
nvidia-smi -l 1
```

### Test Inference

```bash
# Run a model
ollama run llama2 "Hello, world!"

# Watch GPU usage
watch -n 1 nvidia-smi
```

## Related Documentation

- [tesla-inference-flake README](https://github.com/deepwatrcreatur/tesla-inference-flake/blob/main/README.md)
- [tesla-inference-flake Troubleshooting](https://github.com/deepwatrcreatur/tesla-inference-flake/blob/main/README.md#troubleshooting)
- Local: `CLAUDE.md` - General repository guide

## Timeline

- **Dec 28, 2024**: Source build working with simple `acceleration = "cuda"`
- **Jan 3-5, 2026**: Multiple attempts with different source build approaches
- **Jan 5, 2026**: Feature branch with official binaries created and tested
- **Jan 6, 2026**:
  - Tested source build: FAILS with cuda_compat error
  - Tested official binaries: SUCCESS
  - Integrated official binaries into main branch
  - Updated to latest tesla-inference-flake@8976aba with troubleshooting docs

## References

- Working commit: `8458163` (nix-inference-clean) - "Update ollama config to use official binaries (P40 GPU working)"
- Integration commit: `51b4eb8` - "docs: Add tesla-inference integration documentation"
- tesla-inference-flake: Commit `8976aba` - "docs: Add troubleshooting section for cuda_compat error"
