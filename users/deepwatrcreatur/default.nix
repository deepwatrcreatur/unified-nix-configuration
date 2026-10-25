{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    # System-level secrets are handled by agenix at /run/agenix/
    # User-level SOPS secrets are handled as a legacy fallback in user-secrets.nix
    ../../modules/home-manager/user-secrets.nix
    ./rbw.nix
    ./env.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/bitwarden-cli.nix
    ../../modules/home-manager/rclone-scripts.nix
    ../../modules/home-manager/linuxbrew.nix
    ../../modules/home-manager
    ../../modules/home-manager/common/cmux-tui.nix
    ../../modules/home-manager/fastfetch.nix
  ];

  programs.bitwarden-cli = {
    enable = true;
  };

  programs.zellij-vivid-rounded = {
    enable = true;
  };

  programs.fastfetch-custom = {
    enable = true;
  };

  programs.rclone-scripts.secretsPath = ./secrets;

  services.user-secrets = {
    enable = true;
    secretsPath = ./secrets;
  };

  programs.cmux-tui.enable = true;

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  home.file.".gnupg/public-key.asc" = {
    source = ./gpg-public-key.asc; # Remove toString, just use the path directly
  };
}
