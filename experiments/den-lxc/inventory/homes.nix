{
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
