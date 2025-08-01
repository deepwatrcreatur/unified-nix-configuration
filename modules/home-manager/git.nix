# modules/home-manager/git.nix
{ config, pkgs, lib, inputs, ... }:
let
  # Define shell aliases for reuse across shells
  shellAliases = {
    "g" = "git";
    "ga" = "git add";
    "gaa" = "git add --all";
    "gau" = "git add --update";
    "gav" = "git add --verbose";
    "gb" = "git branch";
    "gba" = "git branch -a";
    "gbd" = "git branch -d";
    "gbD" = "git branch -D";
    "gbl" = "git blame -b -w";
    "gbnm" = "git branch --no-merged";
    "gbr" = "git branch --remote";
    "gbs" = "git bisect";
    "gbsb" = "git bisect bad";
    "gbsg" = "git bisect good";
    "gbsr" = "git bisect reset";
    "gbss" = "git bisect start";
    "gc" = "git commit -v";
    "gca" = "git commit -v -a";
    "gcas" = "git commit -a -s";
    "gcb" = "git checkout -b";
    "gcl" = "git clone --recurse-submodules";
    "gclean" = "git clean -id";
    "gpristine" = "git reset --hard; git clean -dffx";
    "gco" = "git checkout";
    "gcount" = "git shortlog -sn";
    "gcp" = "git cherry-pick";
    "gcpa" = "git cherry-pick --abort";
    "gcpc" = "git cherry-pick --continue";
    "gd" = "git diff";
    "gdtd" = "git difftool -g --dir-diff";
    "gdca" = "git diff --cached";
    "gdcw" = "git diff --cached --word-diff";
    "gdct" = "git describe --tags (^git rev-list --tags --max-count=1)"; 
    "gds" = "git diff --staged";
    "gdt" = "git diff-tree --no-commit-id --name-only -r";
    "gdw" = "git diff --word-diff";
    "gf" = "git fetch";
    "gfa" = "git fetch --all --prune";
    "gfg" = "git ls-files | grep";
    "gignored" = ''git ls-files -v | grep "^[[:lower:]]"'';
    "glo" = "git log --oneline --decorate";
    "glols" = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --stat";
    "glola" = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --all";
    "glog" = "git log --oneline --decorate --graph";
    "gloga" = "git log --oneline --decorate --graph --all";
    "gm" = "git merge";
    "gma" = "git merge --abort";
    "gp" = "git push";
    "gpa" = "git push --all";
    "gpoat" = "git push origin --all; git push origin --tags";
    "gpu" = "git push upstream";
    "gpv" = "git push -v";
    "gr" = "git remote";
    "gra" = "git remote add";
    "grb" = "git rebase";
    "grba" = "git rebase --abort";
    "grbc" = "git rebase --continue";
    "grbi" = "git rebase -i";
    "grev" = "git revert";
    "grh" = "git reset";
    "grhh" = "git reset --hard";
    "grm" = "git rm";
    "grmc" = "git rm --cached";
    "grs" = "git restore";
    "grv" = "git remote -v";
    "gss" = "git status -s";
    "gst" = "git status";
    "gsta" = "git stash push";
    "gstas" = "git stash save";
    "gstaa" = "git stash apply";
    "gstc" = "git stash clear";
    "gstd" = "git stash drop";
    "gstl" = "git stash list";
    "gstp" = "git stash pop";
    "gsts" = "git stash show --text";
    "gup" = "git pull --rebase";
    "gupv" = "git pull --rebase -v";
  };
  # Convert shellAliases to Nushell alias commands
  nushellAliases = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "alias ${name} = ${value}") shellAliases
  );
in
{
  options.programs.git.gui = {
    enable = lib.mkEnableOption "Enable GUI tools like meld for Git";
  };

  config = {
    home.packages = with pkgs; [
      gitAndTools.delta
      mergiraf
      gh
      lazygit
    ] ++ lib.optionals config.programs.git.gui.enable [ meld ];

    programs.git = {
      enable = true;
      package = pkgs.git;
      userName = "Anwer Khan";
      userEmail = "deepwatrcreatur@gmail.com";

      extraConfig = {
        init.defaultBranch = "main";
        core.editor = "hx";
        core.fsmonitor = true;
        core.pager = "delta";
        interactive.diffFilter = "delta --color-only";

        # GitHub credential helpers
        "credential \"https://github.com\"".helper = "!gh auth git-credential";
        "credential \"https://gist.github.com\"".helper = "!gh auth git-credential";

        commit.gpgsign = true;
        user.signingkey = "EF1502C27653693B";

        # Diff drivers
        "diff.elixir".command = "git diff --color-words";
        "diff.rust".command = "git diff --color-words";
        "diff.markdown".command = "git diff --color-words";
        "diff.json".command = "git diff --color-words";
        "diff.python".command = "git diff --color-words";
        "diff.bash".command = "git diff --color-words";
        "diff.nix".command = "git diff --color-words";

        # Delta settings
        delta.navigate = true;
        delta.syntax-theme = "Dracula";
        delta.line-numbers = true;
        delta.side-by-side = true;

        # Additional configurations
        add.interactive.useBuiltin = false;
        branch.sort = "-committerdate";
        column.ui = "auto";
        diff.algorithm = "histogram";
        diff.colorMoved = "default";
        diff.tool = "vimdiff";
        merge.conflictstyle = "diff3";
        merge.tool = "vimdiff";
        pull.rebase = true;
        push.autoSetupRemote = true;
        rebase.autoStash = true;
        rebase.autoSquash = true;
        rerere.enabled = true;
        rerere.autoUpdate = true;
        tag.sort = "version:refname";
      } // lib.optionalAttrs config.programs.git.gui.enable {
        diff.guitool = "meld";
        merge.guitool = "meld";
      };

      aliases = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
        graph = "mergiraf";
        g = "!git";
        ga = "add";
        gaa = "add --all";
        gau = "add --update";
        gav = "add --verbose";
        gb = "branch";
        gba = "branch -a";
        gbd = "branch -d";
        gbD = "branch -D";
        gbl = "blame -b -w";
        gbnm = "branch --no-merged";
        gbr = "branch --remote";
        gbs = "bisect";
        gbsb = "bisect bad";
        gbsg = "bisect good";
        gbsr = "bisect reset";
        gbss = "bisect start";
        gc = "commit -v";
        gcamend = "commit -v --amend";
        gcnoedit = "commit -v --no-edit --amend";
        gca = "commit -v -a";
        gcaamend = "commit -v -a --amend";
        gcanoedit = "commit -v -a --no-edit --amend";
        gcansign = "commit -v -a -s --no-edit --amend";
        gcas = "commit -a -s";
        gcb = "checkout -b";
        gcl = "clone --recurse-submodules";
        gclean = "clean -id";
        gpristine = "!git reset --hard; git clean -dffx";
        gco = "checkout";
        gcount = "shortlog -sn";
        gcp = "cherry-pick";
        gcpa = "cherry-pick --abort";
        gcpc = "cherry-pick --continue";
        gd = "diff";
        gdtd = "difftool -g --dir-diff";
        gdca = "diff --cached";
        gdcw = "diff --cached --word-diff";
        gdct = "!git describe --tags $(git rev-list --tags --max-count=1)";
        gds = "diff --staged";
        gdt = "diff-tree --no-commit-id --name-only -r";
        gdw = "diff --word-diff";
        gf = "fetch";
        gfa = "fetch --all --prune";
        gfg = "!git ls-files | grep";
        gignored = "!git ls-files -v | grep '^[[:lower:]]'";
        glo = "log --oneline --decorate";
        glols = "log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --stat";
        glola = "log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --all";
        glog = "log --oneline --decorate --graph";
        gloga = "log --oneline --decorate --graph --all";
        gm = "merge";
        gma = "merge --abort";
        gp = "push";
        gpa = "push --all";
        gpforce = "push --force-with-lease";
        gpoat = "!git push origin --all; git push origin --tags";
        gpu = "push upstream";
        gpv = "push -v";
        gr = "remote";
        gra = "remote add";
        grb = "rebase";
        grba = "rebase --abort";
        grbc = "rebase --continue";
        grbi = "rebase -i";
        grev = "revert";
        grh = "reset";
        grhh = "reset --hard";
        grm = "rm";
        grmc = "rm --cached";
        grs = "restore";
        grv = "remote -v";
        gss = "status -s";
        gst = "status";
        gsta = "stash push";
        gstas = "stash save";
        gstaa = "stash apply";
        gstc = "stash clear";
        gstd = "stash drop";
        gstl = "stash list";
        gstp = "stash pop";
        gsts = "stash show --text";
        gup = "pull --rebase";
        gupv = "pull --rebase -v";
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

      lfs.enable = true;
    };

    programs.bash.shellAliases = shellAliases;
    programs.zsh.shellAliases = shellAliases;
    programs.fish.shellAliases = shellAliases;
    programs.nushell.extraConfig = nushellAliases;
  };
}
