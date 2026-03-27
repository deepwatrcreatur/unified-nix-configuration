{
  proxmox-root = {
    kind = "home";
    name = "proxmox-root";
    targetSystem = "x86_64-linux";
    hostName = "proxmox-root";
    userPath = ../../../users/root;
    modules = [
      ../../../profiles/home-manager/proxmox-root.nix
    ];
    isDesktop = false;
    mode = "legacy";
  };

  pve-gateway-root = {
    kind = "home";
    name = "pve-gateway-root";
    targetSystem = "x86_64-linux";
    hostName = "pve-gateway";
    userPath = ../../../users/root;
    modules = [
      ../../../profiles/home-manager/proxmox-root.nix
    ];
    isDesktop = false;
    mode = "legacy";
  };

  pve-lattitude-root = {
    kind = "home";
    name = "pve-lattitude-root";
    targetSystem = "x86_64-linux";
    hostName = "pve-lattitude";
    userPath = ../../../users/root;
    modules = [
      ../../../profiles/home-manager/proxmox-root.nix
    ];
    isDesktop = false;
    mode = "legacy";
  };

  pve-rog-root = {
    kind = "home";
    name = "pve-rog-root";
    targetSystem = "x86_64-linux";
    hostName = "pve-rog";
    userPath = ../../../users/root;
    modules = [
      ../../../profiles/home-manager/proxmox-root.nix
    ];
    isDesktop = false;
    mode = "legacy";
  };

  pve-strix-root = {
    kind = "home";
    name = "pve-strix-root";
    targetSystem = "x86_64-linux";
    hostName = "pve-strix";
    userPath = ../../../users/root;
    modules = [
      ../../../profiles/home-manager/proxmox-root.nix
    ];
    isDesktop = false;
    mode = "legacy";
  };

  pve-tomahawk-root = {
    kind = "home";
    name = "pve-tomahawk-root";
    targetSystem = "x86_64-linux";
    hostName = "pve-tomahawk";
    userPath = ../../../users/root;
    modules = [
      ../../../profiles/home-manager/proxmox-root.nix
    ];
    isDesktop = false;
    mode = "legacy";
  };
}
