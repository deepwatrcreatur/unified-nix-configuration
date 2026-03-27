let
  pveNodes = [
    { name = "proxmox-root";       hostName = "proxmox-root";   }
    { name = "pve-gateway-root";   hostName = "pve-gateway";    }
    { name = "pve-lattitude-root"; hostName = "pve-lattitude";  }
    { name = "pve-rog-root";       hostName = "pve-rog";        }
    { name = "pve-strix-root";     hostName = "pve-strix";      }
    { name = "pve-tomahawk-root";  hostName = "pve-tomahawk";   }
  ];

  mkProxmoxHome = { name, hostName }: {
    kind = "home";
    inherit name hostName;
    targetSystem = "x86_64-linux";
    userPath = ../../users/root;
    modules = [ ../../profiles/home-manager/proxmox-root.nix ];
    isDesktop = false;
    mode = "legacy";
  };
in
builtins.listToAttrs (
  map (node: { name = node.name; value = mkProxmoxHome node; }) pveNodes
)
