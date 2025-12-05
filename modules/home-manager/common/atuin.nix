{ config, pkgs, lib, ... }:

{
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Add shell alias for atuin script run
  programs.bash.shellAliases.asr = "atuin script run";
  programs.zsh.shellAliases.asr = "atuin script run";
  programs.fish.shellAliases.asr = "atuin script run";
  programs.nushell.extraConfig = ''
    alias asr = atuin script run
  '';

  # Sops configuration temporarily disabled due to module conflicts
  # sops = lib.mkIf (builtins.hasAttr "secrets" (config.sops or {}) && builtins.pathExists ../../../secrets/atuin-key.enc) {
  #   secrets."atuin-key" = {
  #     sopsFile = ../../../secrets/atuin-key.enc;
  #     key = "atuin_key";
  #     path = "${config.home.homeDirectory}/.config/atuin/key.json";
  #   };
  # };
}