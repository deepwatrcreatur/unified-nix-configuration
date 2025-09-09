{ config, pkgs, lib, inputs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.deepwatrcreatur = {
      imports = [
        ../../../../users/deepwatrcreatur
        ../../../../users/deepwatrcreatur/hosts/cache-build-server
        ../../../../modules/home-manager
      ];
      
      # Build server specific packages
      home.packages = with pkgs; [
        # Build monitoring tools
        nix-tree
        nix-diff
        nix-top
        
        # Build optimization tools  
        nix-prefetch-git
        nix-prefetch-github
        
        # Additional build server tools
        just  # For build automation
        tokei # Code statistics
      ];

      # Build server specific aliases
      programs.nushell.shellAliases = {
        build-status = "nix-top";
        cache-status = "systemctl status nix-serve";
        cache-logs = "journalctl -u nix-serve -f";
        build-stats = "tokei";
        clean-store = "nix-collect-garbage -d";
      };
    };

    users.root = {
      imports = [
        ../../../../users/root
        ../../../../users/root/hosts/cache-build-server
        ../../../../modules/home-manager
      ];
      
      # Root-specific build server management
      home.packages = with pkgs; [
        nix-tree
        nix-diff
      ];

      programs.nushell.shellAliases = {
        restart-cache = "systemctl restart nix-serve";
        build-cleanup = "nix-collect-garbage -d && nix-store --optimize";
        cache-rebuild = "systemctl restart nix-serve && systemctl status nix-serve";
      };
    };
  };
}
