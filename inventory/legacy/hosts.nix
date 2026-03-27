{
  gateway = {
    name = "gateway";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/gateway;
    isDesktop = false;
  };

  inference1 = {
    name = "inference1";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/inference-vm/hosts/inference1;
  };

  inference2 = {
    name = "inference2";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/inference-vm/hosts/inference2;
  };

  inference3 = {
    name = "inference3";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/inference-vm/hosts/inference3;
  };

  inference-fresh = {
    name = "inference-fresh";
    system = "x86_64-linux";
    hostPath = ../../hosts/nixos/inference-vm/hosts/inference-fresh;
  };
}
