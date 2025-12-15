# modules/home-manager/common/git-aliases.nix
# Git command aliases
{
  config,
  lib,
  ...
}:
let
  # Git aliases - comprehensive set for common git operations
  gitAliases = {
    # Basic git operations
    g = "git";
    ga = "git add";
    gaa = "git add --all";
    gau = "git add --update";
    gav = "git add --verbose";

    # Branch operations
    gb = "git branch";
    gbD = "git branch -D";
    gba = "git branch -a";
    gbd = "git branch -d";
    gbl = "git blame -b -w";
    gbnm = "git branch --no-merged";
    gbr = "git branch --remote";
    gbs = "git bisect";
    gbsb = "git bisect bad";
    gbsg = "git bisect good";
    gbsr = "git bisect reset";
    gbss = "git bisect start";

    # Commit operations
    gc = "git commit -v";
    gca = "git commit -v -a";
    gcas = "git commit -a -s";
    gcb = "git checkout -b";

    # Checkout operations
    gco = "git checkout";

    # Status and info
    gst = "git status";
    gsta = "git stash push";
    gstaa = "git stash apply";
    gstas = "git stash save";
    gstc = "git stash clear";
    gstd = "git stash drop";
    gstl = "git stash list";
    gstp = "git stash pop";
    gsts = "git stash show --text";

    # Diff operations
    gd = "git diff";
    gdca = "git diff --cached";
    gdcw = "git diff --cached --word-diff";
    gds = "git diff --staged";
    gdt = "git diff-tree --no-commit-id --name-only -r";
    gdtd = "git difftool -g --dir-diff";
    gdw = "git diff --word-diff";

    # Fetch/Pull/Push
    gf = "git fetch";
    gfa = "git fetch --all --prune";
    gfg = "git ls-files | grep";
    glo = "git log --oneline --decorate";
    glog = "git log --oneline --decorate --graph";
    gloga = "git log --oneline --decorate --graph --all";
    glola = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --all";
    glols = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --stat";

    # Merge/Rebase
    gm = "git merge";
    gma = "git merge --abort";
    gp = "git push";
    gpa = "git push --all";
    gpu = "git push upstream";
    gpv = "git push -v";
    gr = "git remote";
    gra = "git remote add";
    grb = "git rebase";
    grba = "git rebase --abort";
    grbc = "git rebase --continue";
    grbi = "git rebase -i";
    grev = "git revert";
    grh = "git reset";
    grhh = "git reset --hard";
    grm = "git rm";
    grmc = "git rm --cached";
    grs = "git restore";
    grv = "git remote -v";
    gss = "git status -s";

    # Pull/Rebase
    gup = "git pull --rebase";
    gupv = "git pull --rebase -v";

    # Count and info
    gcount = "git shortlog -sn";
    gcp = "git cherry-pick";
    gcpa = "git cherry-pick --abort";
    gcpc = "git cherry-pick --continue";
  };
in
{
  options.custom.gitAliases = {
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = gitAliases;
      description = "Git command aliases";
      readOnly = true;
    };
  };

  config = {
    custom.gitAliases.aliases = gitAliases;
  };
}
