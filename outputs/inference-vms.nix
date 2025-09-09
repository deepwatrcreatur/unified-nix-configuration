# outputs/inference-vms.nix - GPU Inference VM Configurations
{ helpers, ... }:
{
  # Inference VM 1
  nixosConfigurations.inference1 = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/inference-vm/hosts/inference1;
  };

  # Inference VM 2  
  nixosConfigurations.inference2 = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/inference-vm/hosts/inference2;
  };

  # Inference VM 3
  nixosConfigurations.inference3 = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/nixos/inference-vm/hosts/inference3;
  };
}