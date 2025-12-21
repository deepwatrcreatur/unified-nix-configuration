# modules/home-manager/just-nixos.nix - NixOS-specific Justfile commands
# Note: Only import if host platform matches (condition handled in default.nix)
# Note: Only import if host platform matches (condition handled in default.nix)
{ pkgs, lib, hostName, ... }:
{
  # Append NixOS-specific commands to the base justfile
  home.file.".justfile".text = lib.mkAfter ''
    # NixOS Commands
    # ==============

    # Update NixOS system using nixos-rebuild
    update:
        /run/wrappers/bin/sudo nixos-rebuild switch --flake $NH_FLAKE#${hostName}

    # Update NixOS system using nh helper (requires sudo alias or PATH setup)
    # Note: nh invokes sudo internally; ensure /run/wrappers/bin is first in PATH
    nh-update:
        PATH="/run/wrappers/bin:$PATH" nh os switch

    # Build NixOS system without switching
    build-nixos:
        /run/wrappers/bin/sudo nixos-rebuild build --flake $NH_FLAKE#${hostName}

    # Test NixOS configuration
    test-nixos:
        /run/wrappers/bin/sudo nixos-rebuild test --flake $NH_FLAKE#${hostName}

    # Show NixOS version
    nixos-version:
        cat /etc/nixos-version

    # Search NixOS options
    nixos-search query:
        man configuration.nix | grep -i {{query}}

    # Garbage collect Nix store
    system-gc:
        /run/wrappers/bin/sudo nix-collect-garbage -d

    # Optimize Nix store
    system-optimize:
        /run/wrappers/bin/sudo nix-store --optimise

    # Quick switch (alias for update)
    switch: update
  '';
}
