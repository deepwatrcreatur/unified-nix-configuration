# overlays/packages.nix
# Custom packages defined in pkgs/
{ nixpkgsLib }:

[
  # ProxMenux (Proxmox VE interactive menu)
  (final: prev: {
    proxmenux = prev.callPackage ../pkgs/proxmenux.nix { };
  })

  # Factory.ai Droid CLI
  (final: prev: {
    factory-droid = prev.callPackage ../pkgs/factory-droid.nix { };
  })

  # T3Code (AI code editor)
  (final: prev: {
    t3code = prev.callPackage ../pkgs/t3code.nix { };
  })

  # Wrapped GitHub CLI using fnox-backed token lookup
  (final: prev: {
    gh-fnox = final.callPackage ../pkgs/gh-fnox.nix {
      fnox = final.fnox;
    };
  })
]
