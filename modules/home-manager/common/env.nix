{ config, pkgs, lib, ... }:
{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    GPG_TTY = "(tty)";
  };
  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
    "${config.home.homeDirectory}/.cargo/bin"
    "/home/linuxbrew/.linuxbrew/bin"
    "/home/linuxbrew/.linuxbrew/sbin"
  ];
  
  # Set NH_FLAKE for bash specifically
  programs.bash = {
    sessionVariables = {
    };
    initExtra = ''
      # Determinate nixd completion
      eval "$(determinate-nixd completion bash)"
    '';
  };
  programs.nushell = {
    enable = true;
    extraConfig = ''
    '';
  };
  programs.fish = {
    enable = true;
    shellInit = ''
      
      # Determinate nixd completion
      eval "$(determinate-nixd completion fish)"
    '';
  };
  
  # Add zsh configuration with determinate nixd completion
  programs.zsh = {
    enable = true;
    initContent = ''
      # Determinate nixd completion
      eval "$(determinate-nixd completion zsh)"
    '';
  };
}
