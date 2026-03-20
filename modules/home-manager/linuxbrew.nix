{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  commonPackages = import ../common-brew-packages.nix;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  imports = [ inputs.nix-linuxbrew.homeManagerModules.default ];

  config = lib.mkIf (isLinux && config.home.homeDirectory != null) {
    programs.linuxbrew = {
      enable = lib.mkDefault true;
      taps = lib.mkDefault commonPackages.taps;
      brews = lib.mkDefault commonPackages.brews;
    };

    home.packages = [
      inputs.nix-linuxbrew.packages.${pkgs.stdenv.hostPlatform.system}.brew-wrapper
    ];
  };
}
