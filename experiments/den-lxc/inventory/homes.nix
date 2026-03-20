{
  deepwatrcreatur-inference-node = {
    kind = "home";
    name = "deepwatrcreatur-inference-node";
    targetSystem = "x86_64-linux";
    hostName = "deepwatrcreatur-inference-node";
    userPath = ../../../users/deepwatrcreatur/hosts/inference-node;
    mode = "legacy";
  };

  root-inference-node = {
    kind = "home";
    name = "root-inference-node";
    targetSystem = "x86_64-linux";
    hostName = "root-inference-node";
    userPath = ../../../users/root/hosts/inference-node;
    mode = "legacy";
  };

  proxmox-root = {
    kind = "home";
    name = "proxmox-root";
    targetSystem = "x86_64-linux";
    hostName = "proxmox-root";
    userPath = ../../../users/root;
    modules = [
      ../../../users/root/hosts/proxmox
    ];
    isDesktop = false;
    mode = "legacy";
  };
}
