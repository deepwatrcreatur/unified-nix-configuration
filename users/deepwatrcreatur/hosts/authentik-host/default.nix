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
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    jq
    postgresql
    redis
  ];

  programs.bash.enable = true;
  programs.home-manager.enable = true;

  home.stateVersion = "25.11";
}
