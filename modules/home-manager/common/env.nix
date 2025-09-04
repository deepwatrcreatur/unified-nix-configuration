{ config, pkgs, lib, ... }:
{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    GPG_TTY = "(tty)";
    NH_FLAKE = "${config.home.homeDirectory}/unified-nix-configuration";
  };
  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
    "/home/linuxbrew/.linuxbrew/bin"
    "/home/linuxbrew/.linuxbrew/sbin"
  ];
  
  # Set NH_FLAKE for bash specifically
  programs.bash.sessionVariables = {
    NH_FLAKE = "${config.home.homeDirectory}/unified-nix-configuration";
  };
  programs.nushell = {
    enable = true;
    extraConfig = ''
      $env.PATH = ($env.PATH | split row (char esep) | prepend "/home/linuxbrew/.linuxbrew/bin" | prepend "/home/linuxbrew/.linuxbrew/sbin")
    '';
  };
  programs.fish = {
    enable = true;
    shellInit = ''
      set -gx PATH /home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin $PATH
    '';
  };
}
