# den/aspects/hardware-amdgpu-power-saving.nix
# AMD GPU power management and GFXOFF stability fix.
# Prevents GPU ring timeouts (gfx_0.1.0 timeout) during dynamic power gating
# and power state transitions (particularly on AMD Raphael iGPUs and RDNA2).
_context:
{ ... }:
{
  boot.kernelParams = [
    # GFXOFF is bit 15 (0x8000) of ppfeaturemask. Masking 0x8000 out of default 0xfff7bfff yields 0xfff73fff.
    "amdgpu.ppfeaturemask=0xfff73fff"
    # Disable runtime power management to prevent GPU sleep state drops
    "amdgpu.runpm=0"
  ];
}
