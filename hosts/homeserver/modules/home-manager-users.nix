{ config, pkgs, lib, inputs, ... }:

let
  # Define shared packages to extend home.packages
  sharedPackages = with pkgs; [
    gnupg
    links2
  ];
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; }; # This is good, passes 'inputs' down

    users.deepwatrcreatur = {
      imports = [
        ../../../users/deepwatrcreatur
        ../../../users/deepwatrcreatur/hosts/homeserver
        ../../../modules/home-manager # This might import other HM modules for deepwatrcreatur
                                     # Ensure this (or anything it imports) doesn't try to load gnupg again.
      ];
      home.packages = (config.home.packages or []) ++ sharedPackages ++ [
      ];

    };

    users.root = {
      imports = [
        ../../../users/root
        ../../../users/root/hosts/homeserver
        ../../../modules/home-manager # Ensure this doesn't try to load gnupg
      ];
      home.packages = (config.home.packages or []) ++ sharedPackages ++ [

      ];
    };
  };
}
