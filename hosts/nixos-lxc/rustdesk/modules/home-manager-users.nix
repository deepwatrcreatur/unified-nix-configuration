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
        ../../../../modules/home-manager/git.nix
        ../../../../modules/home-manager/common/starship.nix
        ../../../../modules/home-manager/common/shell-aliases.nix
      ];

      home.username = "root";
      home.homeDirectory = "/root";
      home.stateVersion = "25.11";
      programs.home-manager.enable = true;

      # RustDesk server management packages
      home.packages = with pkgs; [
        just
      ];
    };
  };
}
