# modules/home-manager/nushell/default.nix

{ config, pkgs, lib, ... }:

{
  programs.nushell = {
    enable = true;
    environmentVariables = {
      GPG_TTY = "(tty)";
      BW_SESSION = "$(cat ${config.sops.secrets.BW_SESSION.path}";
    };
    shellAliases = {
      rename = "^rename -n";
      rename-apply = "^rename";
    };
  };

  programs.starship = {
    enableNushellIntegration = true;
  };
}
