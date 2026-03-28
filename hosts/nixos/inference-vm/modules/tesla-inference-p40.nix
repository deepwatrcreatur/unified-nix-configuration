{ lib, ... }:
{
  # Enable tesla-inference-flake integration for all inference VMs (Tesla P40).
  tesla-inference = {
    enable = true;
    gpu = "P40";
    monitoring.enable = true;
  };
}
