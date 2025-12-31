# outputs/inference-vms.nix - GPU Inference VM Configurations
{ helpers, ... }:
helpers.mergeOutputs [
  # Inference VM 1
  (helpers.mkNixosOutput {
    name = "inference1";
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/inference-vm/hosts/inference1;
  })

  # Inference VM 2
  (helpers.mkNixosOutput {
    name = "inference2";
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/inference-vm/hosts/inference2;
  })

  # Inference VM 3
  (helpers.mkNixosOutput {
    name = "inference3";
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/inference-vm/hosts/inference3;
  })

  # Inference Fresh (minimal configuration from fresh-nixos branch)
  (helpers.mkNixosOutput {
    name = "inference-fresh";
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/inference-vm/hosts/inference-fresh;
  })
]
