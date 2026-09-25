# den/aspects/compute-performance.nix
# Compute-performance specialization aspect.
# Tunes kernel parameters, memory hugepages, swap aggressiveness, and CPU governors
# for intensive local LLM inference, machine learning, and multi-core compilation.
{ ... }:
{ lib, ... }:
{
  imports = [
    ../../modules/nixos/specializations/compute-performance.nix
  ];

  myModules.specializations.computePerformance.enable = lib.mkDefault true;
}
