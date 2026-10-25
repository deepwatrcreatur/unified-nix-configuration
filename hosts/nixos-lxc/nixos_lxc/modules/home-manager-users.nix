{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Define shared packages to extend home.packages
  sharedPackages = with pkgs; [
    pinentry-curses
    links2
  ];
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.deepwatrcreatur = {
      imports = [
        ../../../../users/deepwatrcreatur
        ../../../../users/deepwatrcreatur/hosts/nixos-lxc/nixos_lxc
        ../../../../modules/home-manager

      ];
      home.packages =
        (config.home.packages or [ ])
        ++ sharedPackages;
    };

    users.root = {
      imports = [
        ../../../../users/root
        ../../../../modules/home-manager # Ensure this doesn't try to load gnupg
      ];
      home.packages =
        (config.home.packages or [ ])
        ++ sharedPackages;
    };
  };

}
