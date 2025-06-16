{ config, pkgs, lib, inputs, ... }:

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
    extraSpecialArgs = { inherit inputs; }; # This is good, passes 'inputs' down

    users.deepwatrcreatur = {
      imports = [
        ../../../users/deepwatrcreatur
        ../../../users/deepwatrcreatur/hosts/homeserver
        ../../../modules/home-manager # This might import other HM modules for deepwatrcreatur
                                     # Ensure this (or anything it imports) doesn't try to load gnupgain.
      ];
      home.packages = (config.home.packages or []) ++ sharedPackages ++ [        
      ];
      #home.file.".gnupg/gpg-agent.conf".text = ''
      #  pinentry-program ${pkgs.pinentry-curses}/bin/pinentry-curses
        # default-cache-ttl 10800
        # max-cache-ttl 10800
      #  enable-ssh-support
      #'';
      # The idiomatic Home-Manager way
      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        pinentryPackage = "pkgs.pinentry-ncurses";
        # defaultCacheTtl = 10800;
        # maxCacheTtl = 10800;
      };
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
