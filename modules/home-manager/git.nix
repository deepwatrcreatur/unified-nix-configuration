{ config, pkgs, ... }:

{
  # Extend environment.systemPackages to include gitAndTools.delta
  home.packages = with pkgs; [
    gitAndTools.delta
  ];
  
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
      "diff.markdown".command = "git diff --color-words";
      "diff.json".command = "git diff --color-words";
      "diff.python".command = "git diff --color-words";
      "diff.bash".command = "git diff --color-words";
      "diff.nix".command = "git diff --color-words";

      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true; # Enable navigation in large diffs
      delta.syntax-theme = "Dracula"; 
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
      "*.md diff=markdown"         
      "*.json diff=json" 
      "*.py diff=python" 
      "*.sh diff=bash" 
      "*.nix diff=nix"
      "*.lock -diff"
    ];
  };
}
