# modules/home-manager/shell-aliases.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Merge all alias modules
  aliases =
    config.custom.fileAliases.aliases
    // config.custom.gitAliases.aliases
    // config.custom.navigationAliases.aliases
    // config.custom.toolAliases.aliases
    // config.custom.grc.aliases;

  # Raw variants that bypass wrapped aliases
  rawAliasesPosix = {
    gh-raw = "${pkgs.gh}/bin/gh";
    opencode-raw = "command opencode";
    bw-raw = "${pkgs.bitwarden-cli}/bin/bw";
    attic-raw = "${pkgs.attic-client}/bin/attic";
  };

  rawAliasesNushell = {
    gh-raw = "^${pkgs.gh}/bin/gh";
    opencode-raw = "^opencode";
    bw-raw = "^${pkgs.bitwarden-cli}/bin/bw";
    attic-raw = "^${pkgs.attic-client}/bin/attic";
  };
in
{
  imports = [
    ./file-aliases.nix
    ./git-aliases.nix
    ./navigation-aliases.nix
    ./tool-aliases.nix
    ./grc.nix
  ];

  programs = {
    bash = {
      enable = true;
      shellAliases = aliases // rawAliasesPosix;
    };
    zsh = {
      shellAliases = aliases // rawAliasesPosix;
    };
    fish = {
      shellAliases = aliases // rawAliasesPosix;
    };
  };

  # Handle nushell - use shellAliases for all commands
  programs.nushell = {
    # Merge all aliases for nushell (use mkForce to override conflicts)
    shellAliases = lib.mkForce (
      # Convert bash/zsh style aliases to nushell format
      (lib.mapAttrs (name: value: "^${value}") config.custom.fileAliases.aliases)
      // (lib.mapAttrs (name: value: "^${value}") config.custom.gitAliases.aliases)
      // (lib.mapAttrs (name: value: value) config.custom.navigationAliases.aliases)
      # Navigation doesn't need ^
      // (lib.mapAttrs (name: value: "^${value}") config.custom.toolAliases.aliases)
      // config.custom.grc.nushellAliases
      // rawAliasesNushell
    );

    extraConfig = ''
      # KiloCode launcher with proper terminal settings
      def kilocode [...args] {
        # Set environment variables for better terminal compatibility
        $env.TERM = "xterm-256color"
        $env.COLORTERM = "truecolor"
        $env.NODE_OPTIONS = "--max-old-space-size=4096"
        $env.NODE_NO_WARNINGS = "1"
        # Fix backspace and terminal input issues
        $env.STTY = "erase ^?"
        $env.LC_ALL = "en_US.UTF-8"
        $env.LANG = "en_US.UTF-8"
        
        # Launch KiloCode with cleaned environment
        ^kilocode ...$args
      }
    '';
  };
}
