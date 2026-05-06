{
  pkgs,
  ...
}:

{
  imports = [
    ../..
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/git-ssh-signing.nix
    ../../../../modules/home-manager/ssh-agent.nix
    ../../../../modules/home-manager/agenix-user-secrets.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    jq
  ];

  programs.bash.enable = true;
  programs.home-manager.enable = true;

  home.stateVersion = "25.11";
}
