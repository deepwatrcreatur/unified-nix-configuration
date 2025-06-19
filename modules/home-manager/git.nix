# modules/home-manager/git.nix
{ config, pkgs, lib, inputs, ... }:
{
  home.packages = with pkgs; [
    gitAndTools.delta
    mergiraf
    gh
    lazygit
    lazyjj
  ];

  programs.git = {
    enable = true;
    userName = "Anwer Khan";
    userEmail = "deepwatrcreatur@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "hx";
      
      # GitHub credential helpers - YES, these belong here!
      "credential \"https://github.com\"".helper = "!gh auth git-credential";
      "credential \"https://gist.github.com\"".helper = "!gh auth git-credential";

      commit.gpgsign = true;
      user.signingkey = "EF1502C27653693B"; # Your actual GPG key ID

      # Define diff drivers
      "diff.elixir".command = "git diff --color-words";
      "diff.rust".command = "git diff --color-words";
      "diff.markdown".command = "git diff --color-words";
      "diff.json".command = "git diff --color-words";
      "diff.python".command = "git diff --color-words";
      "diff.bash".command = "git diff --color-words";
      "diff.nix".command = "git diff --color-words";

      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
      delta.syntax-theme = "Dracula";
    };

    aliases = {
      co = "checkout";
      br = "branch";
      ci = "commit";
      st = "status";
      # Git alias for mergigraf
      graph = "mergiraf"; 
    };

    attributes = [
      "*.ex diff=elixir"
      "*.exs diff=elixir"
      "*.rs diff=rust"
      "*.md diff=markdown"
      "*.json diff=json"
      "*.py diff=python"
      "*.sh diff=bash"
      "*.nix diff=nix"
      "*.lock -diff"
    ];
  };
}
