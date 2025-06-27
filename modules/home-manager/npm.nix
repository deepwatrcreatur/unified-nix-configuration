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
      nodejs # This includes npm
    ];

    # Create npm configuration file
    home.file.".npmrc".text = ''
      prefix=$HOME/.npm-global
      cache=$HOME/.npm-cache
      init-author-name=Your Name
      init-author-email=your.email@example.com
      init-license=MIT
    '';

    # Add npm global bin directory to PATH
    home.sessionPath = [
      "$HOME/.npm-global/bin"
    ];

    # Create the npm global directory if it doesn't exist
    home.activation.createNpmGlobalDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $HOME/.npm-global
      $DRY_RUN_CMD mkdir -p $HOME/.npm-cache
    '';
  };
}
