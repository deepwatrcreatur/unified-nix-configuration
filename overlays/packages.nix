# overlays/packages.nix
# Custom packages defined in pkgs/
{ nixpkgsLib }:

[
  # ProxMenux (Proxmox VE interactive menu)
  (final: prev: {
    proxmenux = prev.callPackage ../pkgs/proxmenux.nix { };
  })

  # iVentoy Free Edition (PXE ISO menu server)
  (final: prev: {
    iventoy-free = prev.callPackage ../pkgs/iventoy-free.nix { };
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

  # Wrapped Bitwarden CLI using fnox-backed session lookup
  (final: prev: {
    bw-fnox = final.callPackage ../pkgs/bw-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped Attic CLI with fnox-backed login token lookup
  (final: prev: {
    attic-fnox = final.callPackage ../pkgs/attic-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped Proxmox Backup Client with fnox-backed password lookup
  (final: prev: {
    proxmox-backup-client-fnox = final.callPackage ../pkgs/proxmox-backup-client-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped Factory.ai Droid CLI with fnox-backed API key lookup
  (final: prev: {
    factory-droid-fnox = final.callPackage ../pkgs/factory-droid-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped Claude Code CLI with fnox-backed API key lookup
  (final: prev: {
    claude-code-fnox = final.callPackage ../pkgs/claude-code-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped OpenCode CLI with fnox-backed Z_AI_API_KEY lookup.
  # Uses pkgs.llm-agents.opencode (the repo-managed version) instead of the
  # fnox-flake's own bundled opencode, which lags behind the overlay version.
  (final: prev: {
    opencode-zai = final.callPackage ../pkgs/opencode-zai.nix {
      opencode = final.llm-agents.opencode;
      fnox = final.fnox;
    };
  })
]
