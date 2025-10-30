{ config, pkgs, lib, ... }:

let
  secretPath = config.sops.secrets."atuin-key".path;
in
{
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Configure SOPS secret for Atuin key
  sops.secrets."atuin-key" = {
    sopsFile = ../../../secrets/atuin-key.enc;
    key = "atuin_key";
  };

  # Set ATUIN_KEY environment variable by reading the decrypted secret file
  programs.bash.initExtra = ''
    if [[ -f "${secretPath}" ]]; then
      export ATUIN_KEY="$(/bin/cat ${secretPath})"
    fi
  '';

  programs.zsh.initContent = ''
    if [[ -f "${secretPath}" ]]; then
      export ATUIN_KEY="$(/bin/cat ${secretPath})"
    fi
  '';

  programs.fish.interactiveShellInit = ''
    if test -f ${secretPath}
      set -gx ATUIN_KEY (/bin/cat ${secretPath})
    end
  '';

  programs.nushell.extraConfig = ''
    if ("${secretPath}" | path exists) {
      $env.ATUIN_KEY = (open "${secretPath}" | str trim)
    }
  '';
}
