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
    (atuin init nu) | save --force /tmp/atuin_init.nu
    if ("/tmp/atuin_init.nu" | path exists) {
      source /tmp/atuin_init.nu
    }
  ''; 
}
