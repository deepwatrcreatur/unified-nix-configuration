{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.fd;
in
{
  options.programs.fd = {
    enable = mkEnableOption "fd, a fast alternative to find";

    package = mkOption {
      type = types.package;
      default = pkgs.fd;
      defaultText = literalExpression "pkgs.fd";
      description = "The fd package to use.";
    };

    settings = mkOption {
      type = with types; attrsOf (oneOf [ bool int str (listOf str) ]);
      default = {};
      description = "Configuration options for fd.";
      example = literalExpression ''
        {
          hidden = true;
          no-ignore = false;
          follow = true;
          case-sensitive = false;
          max-depth = 10;
          exclude = [ ".git" "node_modules" ".cache" ];
        }
      '';
    };

    aliases = mkOption {
      type = with types; attrsOf str;
      default = {};
      description = "Shell aliases for fd commands.";
      example = literalExpression ''
        {
          fda = "fd -H -I";  # find all (including hidden and ignored)
          fdf = "fd -t f";   # find files only
          fdd = "fd -t d";   # find directories only
          fdx = "fd -t x";   # find executables only
        }
      '';
    };

    defaultExcludes = mkOption {
      type = with types; listOf str;
      default = [
        ".git"
        "node_modules"
        ".cache"
        "target"
        "dist"
        "build"
        ".pytest_cache"
        "__pycache__"
        ".DS_Store"
        "Thumbs.db"
      ];
      description = "Default patterns to exclude from searches.";
    };

    ignoreFile = mkOption {
      type = with types; nullOr path;
      default = null;
      description = "Path to global ignore file for fd.";
    };

    enableShellIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Enable shell integration with useful aliases and functions.";
    };
  };

  config = mkIf cfg.enable (let
    # Define base aliases for all shells
    baseAliases = {
      # Basic enhanced aliases
      fda = "fd --hidden --no-ignore";           # find all files
      fdf = "fd --type file";                    # files only  
      fdd = "fd --type directory";               # directories only
      fdx = "fd --type executable";              # executables only
      fdl = "fd --type symlink";                 # symlinks only
      fds = "fd --case-sensitive";               # case sensitive
      fdi = "fd --no-ignore";                    # ignore .gitignore
      fdh = "fd --hidden";                       # include hidden files
      
      # Size-based searches
      fde = "fd --type empty";                   # empty files/dirs
      
      # Time-based aliases
      fdn = "fd --changed-within 1day";         # files changed in last day
      fdw = "fd --changed-within 1week";        # files changed in last week
      fdm = "fd --changed-within 1month";       # files changed in last month
      
      # Extension-based searches
      fdimg = "fd -e jpg -e jpeg -e png -e gif -e bmp -e svg";
      fdvid = "fd -e mp4 -e avi -e mkv -e mov -e wmv -e flv";
      fdaud = "fd -e mp3 -e wav -e flac -e aac -e ogg";
      fddoc = "fd -e pdf -e doc -e docx -e txt -e md";
      fdcode = "fd -e py -e js -e ts -e rs -e go -e c -e cpp -e java";
    };
    
    # Merge with user-provided aliases
    allAliases = baseAliases // cfg.aliases;
    
    # Convert aliases to nushell format (prefix external commands with ^)
    nushellAliases = mapAttrs (name: value: 
      builtins.replaceStrings ["fd "] ["^fd "] value
    ) allAliases;
  in {
    # Consolidated package declaration
    home.packages = [ cfg.package ] ++ 
      optionals cfg.enableShellIntegration (with pkgs; [
        fzf      # for interactive file selection
        bat      # for file previews
        tree     # for directory previews
      ]);

    # Create fdignore file if excludes are specified
    home.file.".fdignore" = mkIf (cfg.defaultExcludes != []) {
      text = concatStringsSep "\n" cfg.defaultExcludes;
    };

    # Custom ignore file
    home.file.".config/fd/ignore" = mkIf (cfg.ignoreFile != null) {
      source = cfg.ignoreFile;
    };

    # Shell aliases - merged with existing aliases
    programs.bash.shellAliases = mkIf cfg.enableShellIntegration allAliases;
    programs.zsh.shellAliases = mkIf cfg.enableShellIntegration allAliases;
    programs.fish.shellAliases = mkIf cfg.enableShellIntegration allAliases;
    
    # Nushell aliases with ^ prefix for external commands
    programs.nushell.shellAliases = mkIf cfg.enableShellIntegration nushellAliases;

    # Advanced shell functions for bash and zsh
    programs.bash.initExtra = mkIf cfg.enableShellIntegration ''
      # Function to find and edit files with fzf integration
      fde_edit() {
        local file
        file=$(fd --type file | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:60%:wrap)
        [[ -n "$file" ]] && $EDITOR "$file"
      }

      # Function to cd into directory found with fd
      fdc_cd() {
        local dir
        dir=$(fd --type directory | fzf --preview 'tree -C {} | head -200')
        [[ -n "$dir" ]] && cd "$dir"
      }

      # Function to find large files
      fdlarge() {
        fd --type file --exec ls -lah {} \; | sort -k5 -hr | head -20
      }

      # Function to find duplicate filenames
      fddup() {
        fd --type file --exec basename {} \; | sort | uniq -d
      }
    '';

    programs.zsh.initExtra = mkIf cfg.enableShellIntegration ''
      # Same functions for zsh
      fde_edit() {
        local file
        file=$(fd --type file | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:60%:wrap)
        [[ -n "$file" ]] && $EDITOR "$file"
      }

      fdc_cd() {
        local dir
        dir=$(fd --type directory | fzf --preview 'tree -C {} | head -200')
        [[ -n "$dir" ]] && cd "$dir"
      }

      fdlarge() {
        fd --type file --exec ls -lah {} \; | sort -k5 -hr | head -20
      }

      fddup() {
        fd --type file --exec basename {} \; | sort | uniq -d
      }
    '';

    # Fish shell functions
    programs.fish.functions = mkIf cfg.enableShellIntegration {
      fde_edit = ''
        set file (fd --type file | fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:60%:wrap)
        if test -n "$file"
          $EDITOR "$file"
        end
      '';
      
      fdc_cd = ''
        set dir (fd --type directory | fzf --preview 'tree -C {} | head -200')
        if test -n "$dir"
          cd "$dir"
        end
      '';
      
      fdlarge = ''
        fd --type file --exec ls -lah {} \; | sort -k5 -hr | head -20
      '';
      
      fddup = ''
        fd --type file --exec basename {} \; | sort | uniq -d
      '';
    };

    # Nushell custom commands (equivalent to functions)
    programs.nushell.extraConfig = mkIf cfg.enableShellIntegration ''
      # Function to find and edit files with fzf integration
      def fde_edit [] {
        let file = (^fd --type file | ^fzf --preview 'bat --style=numbers --color=always {}' --preview-window=right:60%:wrap)
        if ($file | is-not-empty) {
          if ($env.EDITOR? | is-not-empty) {
            ^$env.EDITOR $file
          } else {
            ^vim $file
          }
        }
      }

      # Function to cd into directory found with fd  
      def fdc_cd [] {
        let dir = (^fd --type directory | ^fzf --preview 'tree -C {} | head -200')
        if ($dir | is-not-empty) {
          cd $dir
        }
      }

      # Function to find large files
      def fdlarge [] {
        ^fd --type file --exec ls -lah {} \; | ^sort -k5 -hr | ^head -20
      }

      # Function to find duplicate filenames
      def fddup [] {
        ^fd --type file --exec basename {} \; | ^sort | ^uniq -d
      }
    '';
  
  });
}

