{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    userName = "Anwer Khan";
    userEmail = "deepwatrcreatur@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "hx";
      "credential \"https://github.com\"".helper = "!gh auth git-credential";
      "credential \"https://gist.github.com\"".helper = "!gh auth git-credential";
    };

    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
    };
  };
}
