# modules/home-manager/just-nixos.nix - NixOS-specific Justfile commands
# Note: Use simpler tmux configuration without problematic enhancements
# Note: Only import if host platform matches (condition handled in default.nix)
{ pkgs, lib, config, ... }:

{
  # Append NixOS-specific commands to base justfile
  home.file.".justfile".text = lib.mkAfter ''
    # NixOS Commands
    # ==============
    # Update NixOS system using nixos-rebuild
    update:
      /run/current-system/sw/bin/sudo /nixos-rebuild switch --flake $NH_FLAKE#${hostName}
    
    # Update NixOS system using nh helper
    nh-update:
      PATH="/run/wrappers/bin:$PATH" nh os switch
    
    # Build NixOS system without switching (dry run)
    build-nixos:
      /run/current-system/sw/bin/sudo /nixos-rebuild build --flake $NH_FLAKE#${hostName}
    
    # Test NixOS configuration
    test-nixos:
      /run/current-system/sw/bin/sudo /nixos-rebuild test --flake $NH_FLAKE#${hostName}
    
    # Show NixOS version
    nixos-version:
      cat /etc/nixos-version
    
    # Search NixOS options
    nixos-search query:
      man configuration.nix | grep -i {{query}}
    '';
  
  # Garbage collect Nix store
    system-gc:
      /run/current-system/sw/bin/sudo /nix-collect-garbage --delete-old
    
    # Optimize Nix store  
    system-optimize:
      /run/current-system/sw/bin/sudo /nix-store --optimise
      
    # Show available memory
    memory-stats:
      free -h
      
    # Show disk usage
    disk-usage:
      df -h
      
    # Quick switch (alias for update)
    switch: update
      
    # Quick rebuild (alias for dry run)
    build-nixos: build-nixos
      
    # Quick test (alias for test)
    test-nixos: test-nixos
      
    # Quick system info
    system-info:
      uname -a
      
    # Quick search (alias for searching)
    nixos-search: nixos-search
      
    # Display available justfile commands
    # This provides all the above in an organized way
  '';
}