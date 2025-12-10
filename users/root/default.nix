{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    # ./sops.nix # <--- Temporarily disabled sops configuration
    ./git.nix # <--- Import git configuration
    ./env.nix
    ../../modules/home-manager/git.nix # Keep this import if it provides other common git modules
    ../../modules/home-manager/gpg-cli.nix
    ../../modules/home-manager
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

   # Allow root to manage Home Manager
   programs.home-manager.enable = true;

   # SSH agent startup in fish shell
   programs.fish.interactiveShellInit = ''
     # Start SSH agent if not already running
     if not set -q SSH_AUTH_SOCK; or not ssh-add -l >/dev/null 2>&1
       eval (ssh-agent -c) >/dev/null
       ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
     end
   '';
}
