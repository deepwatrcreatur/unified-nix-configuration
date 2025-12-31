# modules/home-manager/just-nixos.nix - NixOS-specific Justfile commands
# Note: Only import if host platform matches (condition handled in default.nix)
{ pkgs, lib, hostName, ... }:

{
  # Append NixOS-specific commands to base justfile
  home.file.".justfile".text = lib.mkAfter ''
    # NixOS Commands
    # ==============
    
    # Update NixOS system using nixos-rebuild
    update:
        /run/wrappers/bin/sudo nixos-rebuild switch --flake $NH_FLAKE#${hostName}
    
    # Update NixOS system using nh helper
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
        nixos-version
    
    # Search NixOS options
    nixos-search query:
        nixos-option {{query}} 2>/dev/null || echo "Option not found. Try: man configuration.nix"
    
    # Garbage collect Nix store
    system-gc:
        /run/wrappers/bin/sudo nix-collect-garbage --delete-old
    
    # Optimize Nix store
    system-optimize:
        /run/wrappers/bin/sudo nix-store --optimise
      
    # Show available memory
    memory-stats:
        free -h
      
    # Show disk usage
    disk-usage:
        df -h
      
    # Quick switch (alias for update)
    switch: update
      
    # Quick system info
    system-info:
        uname -a
        nixos-version
  '';
}
