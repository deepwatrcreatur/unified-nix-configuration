{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # Fix home-manager service timeout in LXC - nix daemon needs NIX_REMOTE set
  systemd.services."home-manager-root".environment.NIX_REMOTE = "daemon";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.root = {
      imports = [
        ../../../../users/root
        ../../../../users/root/hosts/attic-cache
        ../../../../modules/home-manager/git.nix
        ../../../../modules/home-manager/gpg-cli.nix
      ];

      home.username = "root";
      home.homeDirectory = "/root";
      home.stateVersion = "25.11";
      programs.home-manager.enable = true;

      # Root-specific build server management
      home.packages = with pkgs; [
        nix-tree
        nix-diff
        nix-top
        nix-prefetch-git
        nix-prefetch-github
        just
        tokei
      ];

      programs.nushell.shellAliases = {
        restart-cache = "systemctl restart nix-serve";
        build-cleanup = "nix-collect-garbage -d && nix-store --optimize";
        cache-rebuild = "systemctl restart nix-serve && systemctl status nix-serve";
        build-status = "nix-top";
        cache-status = "systemctl status nix-serve";
        cache-logs = "journalctl -u nix-serve -f";
        build-stats = "tokei";
        clean-store = "nix-collect-garbage -d";
      };
    };
  };
}
