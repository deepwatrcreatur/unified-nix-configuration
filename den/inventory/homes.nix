let
  libHosts = (import ../../lib/hosts.nix).hosts;
  proxmoxHostNames =
    builtins.sort builtins.lessThan (
      builtins.filter
        (
          name:
          let
            host = libHosts.${name};
          in
          (host.sshUser or "") == "root" && builtins.match "^pve-.*" name != null
        )
        (builtins.attrNames libHosts)
    );

  pveNodes =
    [ { name = "proxmox-root"; hostName = "proxmox-root"; } ]
    ++ map (hostName: {
      name = "${hostName}-root";
      inherit hostName;
    }) proxmoxHostNames;

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
