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
      prefix=${config.home.homeDirectory}/.npm-global
      cache=${config.home.homeDirectory}/.npm-cache
      init-author-name=Anwer Khan
      init-author-email=deepwatrcreatur@gmail.com
      init-license=MIT
    '';

    # Add npm global bin directory to PATH
    home.sessionPath = [
      "$HOME/.npm-global/bin"
    ];

    programs.fish.shellInit = lib.mkIf config.programs.fish.enable ''
      fish_add_path $HOME/.npm-global/bin
    '';
  
    programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''
      export PATH="$HOME/.npm-global/bin:$PATH"
    '';
  
    programs.bash.bashrcExtra = lib.mkIf config.programs.bash.enable ''
      export PATH="$HOME/.npm-global/bin:$PATH"
    '';

    programs.nushell.extraConfig = lib.mkIf config.programs.nushell.enable ''
      $env.PATH = ($env.PATH | split row (char esep) | prepend $"($env.HOME)/.npm-global/bin")
    '';
  
    # Create the npm global directory if it doesn't exist
    home.activation.createNpmGlobalDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-global
      $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-cache
    '';
  };
}
