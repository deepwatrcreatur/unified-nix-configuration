# Home Manager configurations for the root user on each Proxmox node.
#
# These entries are consumed by mkInventoryOutputs -> mkHomeOutput, so they
# do participate in the den output pipeline. They remain mode = "legacy" because
# the den framework has no "home aspect" concept analogous to the NixOS
# aspectsList. Home Manager configs are user-scoped rather than system-scoped
# and do not map cleanly onto the current aspect model.
#
# Migration path: there is no current plan. The proxmox-root profile is small
# and stable; defining a home-manager aspect layer for it would add complexity
# without a clear benefit.
#
# The outputs/checks.nix consistency check verifies that every pve-* host in
# lib/hosts.nix has a matching "-root" home entry here, so additions to
# lib/hosts.nix are automatically reflected.
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
    # Intentionally legacy: no home-manager aspect concept exists in den.
    # These configs are user-scoped (root on Proxmox) and do not fit the
    # NixOS aspectsList model. Keep legacy until a home-manager aspect
    # layer is explicitly designed.
    mode = "legacy";
  };
in
builtins.listToAttrs (
  map (node: { name = node.name; value = mkProxmoxHome node; }) pveNodes
)
