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
  programs.nushell.extraConfig = ''
    let atuin_init = (atuin init nu | complete | get stdout)
    $atuin_init | save --force /tmp/atuin_init.nu
    source /tmp/atuin_init.nu
  ''; 
}
