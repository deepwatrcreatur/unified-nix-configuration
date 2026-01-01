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
        ../../../../modules/home-manager
      ];

      home.username = "root";
      home.homeDirectory = "/root";
      home.stateVersion = "25.11";
      programs.home-manager.enable = true;
    };

    # Deepwatrcreatur user with full home-manager setup
    users.deepwatrcreatur = {
      imports = [
        ../../../../users/deepwatrcreatur/hosts/rustdesk
      ];

      home.homeDirectory = "/home/deepwatrcreatur";
    };
  };
}
