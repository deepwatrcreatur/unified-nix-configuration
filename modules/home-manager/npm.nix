# modules/home-manager/npm.nix
{ config, pkgs, lib, ... }:

{
  options.myModules.npm.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to enable global npm configuration and ensure nodejs is present.";
  };

  config = lib.mkIf config.myModules.npm.enable {
    home.packages = with pkgs; [
      nodejs # Essential for npm
    ];

    programs.nodejs = {
      enable = true;
      npm = {
        npmrc = ''
          prefix=$HOME/.npm-global
        '';
      };
    };

    # Optionally, ensure the global bin directory is in PATH.
    # Home Manager's programs.npm.enable often handles this, but it's good to be aware.
    # home.sessionVariables = {
    #   PATH = [ "$HOME/.npm-global/bin" ];
    # };
  };
}
