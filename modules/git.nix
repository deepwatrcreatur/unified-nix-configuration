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

      # Define diff drivers
      "diff.elixir".command = "git diff --color-words";
      "diff.rust".command = "git diff --color-words";
    };

    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
    };

    attributes = [
      "*.ex diff=elixir"
      "*.exs diff=elixir"
      "*.rs diff=rust"
    ];
  };
}
