# modules/home-manager/git.nix
{
  config,
  pkgs,
  lib,
  inputs,
  hostName,
  isDesktop ? false,
  ...
}:
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
    "gco" = "git checkout";
    "gcount" = "git shortlog -sn";
    "gcp" = "git cherry-pick";
    "gcpa" = "git cherry-pick --abort";
    "gcpc" = "git cherry-pick --continue";
    "gd" = "git diff";
    "gdtd" = "git difftool -g --dir-diff";
    "gdca" = "git diff --cached";
    "gdcw" = "git diff --cached --word-diff";
    "gds" = "git diff --staged";
    "gdt" = "git diff-tree --no-commit-id --name-only -r";
    "gdw" = "git diff --word-diff";
    "gf" = "git fetch";
    "gfa" = "git fetch --all --prune";
    "gfg" = "git ls-files | grep";
    "glo" = "git log --oneline --decorate";
    "glols" =
      "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --stat";
    "glola" =
      "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --all";
    "glog" = "git log --oneline --decorate --graph";
    "gloga" = "git log --oneline --decorate --graph --all";
    "gm" = "git merge";
    "gma" = "git merge --abort";
    "gp" = "git push";
    "gpa" = "git push --all";
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

  # Special aliases that need different handling for nushell
  nushellSpecialAliases = {
    "gpoat" = "git push origin --all; git push origin --tags";
    # "gpristine" = "git reset --hard; git clean -dffx";  # DISABLED - too dangerous for auto-execution
    # Simplified versions that work as aliases
    "gdct" = "^git describe --tags";
    "gignored" = "^git ls-files -v";
  };

  # Convert shellAliases to Nushell alias commands with proper external command syntax
  # Filter out aliases that contain dangerous multi-command syntax
  filteredShellAliases = lib.filterAttrs (
    name: value:
    # Only include simple single-command aliases - exclude anything with:
    !lib.hasInfix ";" value
    # No semicolons
    && !lib.hasInfix "&&" value
    # No double ampersands
    && !lib.hasInfix "|" value
    # No pipes
    && !lib.hasInfix "(" value # No subcommands
  ) shellAliases;

  # Simple, safe single-command aliases for nushell
  nushellSafeAliases = {
    "gdct" = "git describe --tags";
    "gignored" = "git ls-files -v";
  };

  # Create nushell functions for complex multi-command operations
  nushellFunctions = ''
    # Multi-command git functions (safe - only execute when called)
    def gpoat [] {
      print "Pushing all branches and tags..."
      git push origin --all
      git push origin --tags
      print "Done!"
    }

    def gpristine [] {
      print "⚠️  WARNING: This will delete ALL untracked files and reset to HEAD!"
      print "This action cannot be undone. Are you sure? (y/N)"
      let confirm = (input)
      if ($confirm | str downcase) == "y" {
        print "Resetting and cleaning..."
        git reset --hard
        git clean -dffx
        print "Repository reset to pristine state."
      } else {
        print "Cancelled - no changes made."
      }
    }

    # Enhanced git status with nushell formatting
    def gstatus [] {
      git status --porcelain | lines | parse "{status} {file}" | where status != ""
    }
  '';

  nushellAliases =
    lib.concatStringsSep "\n" (
      (lib.mapAttrsToList (name: value: "alias ${name} = ^${value}") filteredShellAliases)
      ++ (lib.mapAttrsToList (name: value: "alias ${name} = ^${value}") nushellSafeAliases)
    )
    + "\n\n"
    + nushellFunctions;
in
{
  options.programs.git.gui = {
    enable = lib.mkEnableOption "Enable GUI tools like meld for Git";
  };

  config = {
    # Shell configurations that merge with existing configs from other modules
    programs.bash.initExtra = lib.mkAfter ''
      if [ -f ~/.config/nix/nix.conf ]; then
        export GITHUB_TOKEN="$(grep 'access-tokens.*github.com:' ~/.config/nix/nix.conf | sed 's/access-tokens = github.com://')"
      fi

      # GPG settings for automated commits (prevents password prompts in CI/agents)
      export GPG_TTY=$(tty 2>/dev/null || echo "")
      # Allow automated tools to bypass pinentry when in non-interactive mode
      if [ -z "$TERM" ] || [ "$TERM" = "dumb" ]; then
        export GPG_TERMINAL_PROMPT_DISABLE=1
      fi

      # SSH environment: disable interactive TUI features over SSH
      if [ -n "$SSH_CONNECTION" ]; then
        export CI=true
        export TERM=linux
        export NO_COLOR=1
        # Disable OpenCode plugins that cause issues over SSH
        export OPENCODE_DISABLE_PLUGINS=1
      fi
    '';

    programs.zsh.initContent = lib.mkAfter ''
      if [ -f ~/.config/nix/nix.conf ]; then
        export GITHUB_TOKEN="$(grep 'access-tokens.*github.com:' ~/.config/nix/nix.conf | sed 's/access-tokens = github.com://')"
      fi

      # GPG settings for automated commits (prevents password prompts in CI/agents)
      export GPG_TTY=$(tty 2>/dev/null || echo "")
      # Allow automated tools to bypass pinentry when in non-interactive mode
      if [ -z "$TERM" ] || [ "$TERM" = "dumb" ]; then
        export GPG_TERMINAL_PROMPT_DISABLE=1
      fi

      # SSH environment: disable interactive TUI features over SSH
      if [ -n "$SSH_CONNECTION" ]; then
        export CI=true
        export TERM=linux
        export NO_COLOR=1
        # Disable OpenCode plugins that cause issues over SSH
        export OPENCODE_DISABLE_PLUGINS=1
      fi
    '';

    programs.fish.interactiveShellInit = lib.mkAfter ''
      if test -f ~/.config/nix/nix.conf
        set -gx GITHUB_TOKEN (grep 'access-tokens.*github.com:' ~/.config/nix/nix.conf | sed 's/access-tokens = github.com://')
      end

      # GPG settings for automated commits (prevents password prompts in CI/agents)
      set -gx GPG_TTY (tty 2>/dev/null; or echo "")
      # Allow automated tools to bypass pinentry when in non-interactive mode
      if test -z "$TERM" -o "$TERM" = "dumb"
        set -gx GPG_TERMINAL_PROMPT_DISABLE 1
      end

      # SSH environment: disable interactive TUI features over SSH
      if test -n "$SSH_CONNECTION"
        set -gx CI true
        set -gx TERM linux
        set -gx NO_COLOR 1
        # Disable OpenCode plugins that cause issues over SSH
        set -gx OPENCODE_DISABLE_PLUGINS 1
      end
    '';

    programs.nushell.extraConfig = lib.mkAfter ''
      # Set GitHub token for API access (from nix.conf)
      if ("~/.config/nix/nix.conf" | path exists) {
        let token = (open ~/.config/nix/nix.conf | grep "access-tokens.*github.com:" | str replace "access-tokens = github.com:" "" | str trim)
        if ($token != "") {
          $env.GITHUB_TOKEN = $token
        }
      }

      # GPG settings for automated commits (prevents password prompts in CI/agents)
      $env.GPG_TTY = (try { tty } catch { "" })
      # Allow automated tools to bypass pinentry when in non-interactive mode
      if ($env.TERM == "" or $env.TERM == "dumb") {
        $env.GPG_TERMINAL_PROMPT_DISABLE = "1"
      }

      # SSH environment: disable interactive TUI features over SSH
      if ($env.SSH_CONNECTION? != null) {
        $env.CI = "true"
        $env.TERM = "linux"
        $env.NO_COLOR = "1"
        # Disable OpenCode plugins that cause issues over SSH
        $env.OPENCODE_DISABLE_PLUGINS = "1"
      }

      ${nushellAliases}
    '';

    # Setup .netrc for GitHub authentication in nix flake operations
    home.activation.setupGitHubNetrc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      token_file="$HOME/.config/git/github-token"
      if [ -f "$token_file" ]; then
        TOKEN=$(${pkgs.coreutils}/bin/cat "$token_file" 2>/dev/null | tr -d '\n' || echo "")
        if [ -n "$TOKEN" ]; then
          netrc_file="$HOME/.netrc"
          # Remove any existing github.com entry
          if [ -f "$netrc_file" ]; then
            grep -v "^machine github.com" "$netrc_file" > "$netrc_file.tmp" 2>/dev/null || true
            ${pkgs.coreutils}/bin/mv "$netrc_file.tmp" "$netrc_file" 2>/dev/null || true
          fi
          # Append github.com entry with token
          {
            echo "machine github.com"
            echo "login git"
            echo "password $TOKEN"
          } >> "$netrc_file"
          ${pkgs.coreutils}/bin/chmod 600 "$netrc_file"
          $verbose && echo "GitHub authentication configured in $netrc_file for nix flake operations"
        fi
      fi
    '';

    home.packages =
      with pkgs;
      [
        delta
        mergiraf
        gh
        lazygit
        difftastic # Add difftastic to the list of packages
      ]
      ++ lib.optionals isDesktop [ meld ];

    programs.git = {
      enable = true;
      package = pkgs.git;
      settings = {
        user.name = "Anwer Khan";
        user.email = "deepwatrcreatur@gmail.com";
        core.excludesfile = "${config.xdg.configHome}/git/ignore";
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
        diff.external = "${pkgs.difftastic}/bin/difft"; # Use difftastic as the external diff tool
        merge.conflictstyle = "diff3";
        merge.tool = "vimdiff";
        pull.rebase = true;
        push.autoSetupRemote = true;
        rebase.autoStash = true;
        rebase.autoSquash = true;
        rerere.enabled = true;
        rerere.autoUpdate = true;
        tag.sort = "version:refname";
        alias = {
          co = "checkout";
          br = "branch";
          ci = "commit";
          st = "status";
          graph = "mergiraf";
        };
        url."ssh://git@github.com/".insteadOf = "https://github.com/";
      }
      // lib.optionalAttrs isDesktop {
        diff.guitool = "meld";
        merge.guitool = "meld";
      };

      lfs.enable = true;
    };

    xdg.configFile."git/ignore".source = ./files/gitignore_global;

    # Shell aliases that merge with existing configs
    programs.bash.shellAliases = lib.mkMerge [ shellAliases ];
    programs.zsh.shellAliases = lib.mkMerge [ shellAliases ];
    programs.fish.shellAliases = lib.mkMerge [ shellAliases ];
  };
}
