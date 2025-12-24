{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Add shell alias for atuin script run (if atuin is available)
  programs.bash.initExtra = ''
    if command -v atuin &>/dev/null; then
      alias asr="atuin script run"
    fi
  '';
  programs.zsh.initContent = ''
    if command -v atuin &>/dev/null; then
      alias asr="atuin script run"
    fi
  '';
  programs.fish.shellInit = lib.mkAfter ''
    # Set ATUIN_SESSION for atuin (if available)
    if command -v atuin &>/dev/null
      set -gx ATUIN_SESSION (atuin uuid)
      alias asr "atuin script run"
    end
  '';
  programs.nushell.extraConfig = lib.mkAfter ''
    if (which atuin | is-not-empty) {
      alias asr = atuin script run
    }
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
