{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # Development environments
    devenv
    direnv
    lorri
    
    # Nix health and diagnostics
    nix-health
    nix-inspect
    
    # Nix analysis and visualization
    nix-visualize
    
    # Nix helper tools
    nh
    
    # Nix visualization and monitoring
    nix-output-monitor
    nix-tree
    nvd
    
    # Nix formatting and linting
    nixfmt
    nixpkgs-fmt
    statix
    
    # Nix language servers (for editors)
    nil
    nixd
    
    # cached-nix-shell  # Broken on macOS due to nokogiri compilation issues
  ];
}
