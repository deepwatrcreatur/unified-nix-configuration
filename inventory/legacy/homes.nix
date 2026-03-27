{
  proxmox-root = {
    name = "proxmox-root";
    targetSystem = "x86_64-linux";
    hostName = "proxmox-root";
    userPath = ../../users/root;
    modules = [ ../../users/root/hosts/proxmox ];
    isDesktop = false;
  };

  pve-gateway-root = {
    name = "pve-gateway-root";
    targetSystem = "x86_64-linux";
    hostName = "pve-gateway";
    userPath = ../../users/root;
    modules = [ ../../users/root/hosts/proxmox ];
    isDesktop = false;
  };

  pve-lattitude-root = {
    name = "pve-lattitude-root";
    targetSystem = "x86_64-linux";
    hostName = "pve-lattitude";
    userPath = ../../users/root;
    modules = [ ../../users/root/hosts/proxmox ];
    isDesktop = false;
  };

  pve-rog-root = {
    name = "pve-rog-root";
    targetSystem = "x86_64-linux";
    hostName = "pve-rog";
    userPath = ../../users/root;
    modules = [ ../../users/root/hosts/proxmox ];
    isDesktop = false;
  };

  pve-strix-root = {
    name = "pve-strix-root";
    targetSystem = "x86_64-linux";
    hostName = "pve-strix";
    userPath = ../../users/root;
    modules = [ ../../users/root/hosts/proxmox ];
    isDesktop = false;
  };

  pve-tomahawk-root = {
    name = "pve-tomahawk-root";
    targetSystem = "x86_64-linux";
    hostName = "pve-tomahawk";
    userPath = ../../users/root;
    modules = [ ../../users/root/hosts/proxmox ];
    isDesktop = false;
  };
}
