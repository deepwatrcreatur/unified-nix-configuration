{ config, pkgs, lib, ... }:

{
  programs.atuin.enable = true;

  programs.bash.initExtra = ''
    eval "$(${pkgs.atuin}/bin/atuin init bash)"
  '';
  programs.zsh.initExtra = ''
    eval "$(${pkgs.atuin}/bin/atuin init zsh)"
  '';
  programs.fish.shellInit = lib.mkAfter ''
    atuin init fish | source
  '';

  # Generate atuin config file during build
  home.file.".config/nushell/atuin-init.nu".source = pkgs.runCommand "atuin-nushell-init" {} ''
    ${pkgs.atuin}/bin/atuin init nu > $out
  '';
  
  programs.nushell.extraConfig = ''
    source ~/.config/nushell/atuin-init.nu
  '';
}
