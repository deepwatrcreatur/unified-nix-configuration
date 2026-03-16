{
  inputs,
  commonNixpkgsConfig,
  nixpkgsLib,
}:
[
  (final: prev: {
    inherit (inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}) tailscale;
  })
  # Grok CLI overlay
  (final: prev: {
    fish = prev.fish.overrideAttrs (_oldAttrs: {
      doCheck = false;
    });
  })

  # Prefer COSMIC packages from nixpkgs-unstable (Dec 11 fixes)
  (final: prev:
    nixpkgsLib.optionalAttrs prev.stdenv.isLinux {
      # Import specific COSMIC packages from unstable
      inherit
        (import inputs.nixpkgs-unstable {
          system = prev.stdenv.hostPlatform.system;
          config = commonNixpkgsConfig;
        })
        xdg-desktop-portal-cosmic
        cosmic-greeter
        cosmic-panel
        cosmic-applets
        cosmic-icons
        cosmic-settings
        cosmic-term
        cosmic-store
        cosmic-files
        cosmic-randr
        cosmic-edit
        cosmic-screenshot
        cosmic-bg
        cosmic-comp
        cosmic-session
        ;
    })

  # Worktrunk (git worktree management for parallel agents)
  (final: prev: {
    worktrunk = inputs.worktrunk.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # ProxMenux (Proxmox VE interactive menu)
  (final: prev: {
    proxmenux = import ../pkgs/proxmenux.nix { inherit prev; };
  })

  # Factory.ai Droid CLI (prebuilt binary, patched on NixOS)
  # Factory publishes both "x64" and "x64-baseline" for Linux. The baseline
  # artifact currently appears to be Bun itself, while the "x64" artifact is
  # the actual droid CLI. The official installer selects based on AVX2.
  (
    final: prev: {
      factory-droid = import ../pkgs/factory-droid.nix {
        inherit prev nixpkgsLib;
      };
    }
  )

  # Opencode CLI from nixpkgs-unstable (v1.2.13)
  # The fnox wrappers (opencode-zai, opencode-claude) automatically use this opencode.
  (final: prev: {
    opencode = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.opencode;
  })

  # Tesla inference overlays for GPU optimization
  inputs.tesla-inference-flake.overlays.ollama-official-binaries
  inputs.tesla-inference-flake.overlays.llama-cpp-tesla
  inputs.tesla-inference-flake.overlays.gpu-tools
  # Try to use fnox from nixpkgs first, fallback to flake input if not available
  (final: prev: {
    fnox =
      if prev.stdenv.isLinux && prev.stdenv.hostPlatform.isx86_64 then
        (prev.fnox or inputs.fnox.packages.${prev.stdenv.hostPlatform.system}.default)
      else
        inputs.fnox.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # T3Code (AI code editor)
  (final: prev: {
    t3code = import ../pkgs/t3code.nix { inherit prev; };
  })
]
