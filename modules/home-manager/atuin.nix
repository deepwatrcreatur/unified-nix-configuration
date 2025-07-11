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

  # Create placeholder file
  home.file.".config/nushell/atuin.nu".text = ''
    # Atuin integration for nushell
    # This file will be populated when you first run nushell
  '';
  
  programs.nushell.extraConfig = ''
    # Initialize atuin if not already done
    let atuin_file = ($env.HOME | path join ".config" "nushell" "atuin.nu")
    let atuin_content = (open $atuin_file)
    if ($atuin_content | str contains "# This file will be populated") {
      atuin init nu | save --force $atuin_file
    }
    source $atuin_file
  '';  
}
