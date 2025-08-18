{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.ripgrep-enhanced;
in
{
  options.programs.ripgrep-enhanced = {
    enable = mkEnableOption "ripgrep with enhanced configuration" // {
      default = true;
      arguments = [ "--smart-case" ];
    };

    package = mkOption {
      type = types.package;
      default = pkgs.ripgrep;
      defaultText = literalExpression "pkgs.ripgrep";
      description = "The ripgrep package to use.";
    };

    arguments = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "--smart-case" "--follow" "--hidden" ];
      description = "Default arguments to pass to ripgrep.";
    };

    aliases = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = {
        rgf = "rg --files";
        rgh = "rg --hidden";
        rgz = "rg --search-zip";
      };
      description = "Shell aliases for ripgrep commands.";
    };

    ignoreFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to global ignore file for ripgrep.";
    };

    createIgnoreFile = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to create a default global ignore file.";
    };

    ignorePatterns = mkOption {
      type = types.listOf types.str;
      default = [
        "*.log"
        "*.tmp"
        "*.temp"
        "*~"
        "*.swp"
        "*.swo"
        ".DS_Store"
        "Thumbs.db"
        "node_modules/"
        ".git/"
        ".svn/"
        ".hg/"
        ".bzr/"
        "_darcs/"
        "target/"
        "build/"
        "dist/"
        "*.pyc"
        "__pycache__/"
        ".pytest_cache/"
        ".mypy_cache/"
        ".tox/"
        ".coverage"
        "htmlcov/"
        ".nyc_output/"
        "coverage/"
        ".next/"
        ".nuxt/"
        ".cache/"
        "*.lock"
        "yarn.lock"
        "package-lock.json"
        "Cargo.lock"
        "*.min.js"
        "*.min.css"
        "*.map"
      ];
      description = "Patterns to ignore globally when using ripgrep.";
    };

    typeDefinitions = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {
        nix = [ "*.nix" ];
        markdown = [ "*.md" "*.markdown" "*.mdown" "*.mkd" ];
        org = [ "*.org" ];
        config = [ "*.conf" "*.cfg" "*.ini" "*.toml" "*.yaml" "*.yml" ];
        script = [ "*.sh" "*.bash" "*.zsh" "*.fish" ];
        docker = [ "Dockerfile" "Dockerfile.*" "*.dockerfile" "docker-compose*.yml" "docker-compose*.yaml" ];
      };
      description = "Custom file type definitions for ripgrep.";
    };

    enableBashIntegration = mkOption {
      type = types.bool;
      default = config.programs.bash.enable or true;
      description = "Whether to enable Bash integration.";
    };

    enableZshIntegration = mkOption {
      type = types.bool;
      default = config.programs.zsh.enable or false;
      description = "Whether to enable Zsh integration.";
    };

    enableFishIntegration = mkOption {
      type = types.bool;
      default = config.programs.fish.enable or false;
      description = "Whether to enable Fish integration.";
    };

    enableNushellIntegration = mkOption {
      type = types.bool;
      default = config.programs.nushell.enable or false;
      description = "Whether to enable Nushell integration.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Create ripgrep config file
    home.file.".ripgreprc" = mkIf (cfg.arguments != [] || cfg.typeDefinitions != {}) {
      text = ''
        # Default arguments
        ${concatStringsSep "\n" cfg.arguments}
        
        # Custom type definitions
        ${concatStringsSep "\n" (mapAttrsToList (name: patterns: 
          "--type-add\n${name}:${concatStringsSep "," patterns}"
        ) cfg.typeDefinitions)}
      '';
    };

    # Create or use global ignore file
    home.file.".rgignore" = mkIf (cfg.createIgnoreFile || cfg.ignoreFile != null) (
      if cfg.ignoreFile != null then {
        source = cfg.ignoreFile;
      } else {
        text = concatStringsSep "\n" cfg.ignorePatterns;
      }
    );

    # Environment variable to use the config file
    home.sessionVariables = mkIf (cfg.arguments != [] || cfg.typeDefinitions != {}) {
      RIPGREP_CONFIG_PATH = "${config.home.homeDirectory}/.ripgreprc";
    };

    # Shell aliases (combine custom and default)
    programs.bash.shellAliases = mkIf cfg.enableBashIntegration (
      if cfg.aliases != {} then cfg.aliases else {
        rgf = "rg --files";
        rgi = "rg --no-ignore";
        rgh = "rg --hidden";
        rgz = "rg --search-zip";
        rgt = "rg --type-list";
        rgp = "rg --pretty";
      }
    );

    programs.zsh.shellAliases = mkIf cfg.enableZshIntegration (
      if cfg.aliases != {} then cfg.aliases else {
        rgf = "rg --files";
        rgi = "rg --no-ignore";
        rgh = "rg --hidden";
        rgz = "rg --search-zip";
        rgt = "rg --type-list";
        rgp = "rg --pretty";
      }
    );

    programs.fish.shellAliases = mkIf cfg.enableFishIntegration (
      if cfg.aliases != {} then cfg.aliases else {
        rgf = "rg --files";
        rgi = "rg --no-ignore";
        rgh = "rg --hidden";
        rgz = "rg --search-zip";
        rgt = "rg --type-list";
        rgp = "rg --pretty";
      }
    );

    programs.nushell.shellAliases = mkIf cfg.enableNushellIntegration (
      if cfg.aliases != {} then cfg.aliases else {
        rgf = "rg --files";
        rgi = "rg --no-ignore";
        rgh = "rg --hidden";
        rgz = "rg --search-zip";
        rgt = "rg --type-list";
        rgp = "rg --pretty";
      }
    );

    # Shell functions for enhanced functionality
    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      # Ripgrep with fzf integration
      rgfzf() {
        if [ $# -eq 0 ]; then
          echo "Usage: rgfzf <search_pattern> [rg_options...]"
          return 1
        fi
        rg --color=always --line-number --no-heading --smart-case "''${@}" |
          fzf --ansi \
              --color "hl:-1:underline,hl+:-1:underline:reverse" \
              --delimiter : \
              --preview 'bat --color=always {1} --highlight-line {2}' \
              --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
              --bind 'enter:become(nvim {1} +{2})'
      }

      # Search and edit with ripgrep
      rge() {
        local file line
        read -r file line <<< $(rg --no-heading --line-number "''${1:-}" | fzf --delimiter=: --preview 'bat --color=always --line-range {2}: {1}' | cut -d: -f1,2)
        if [[ -n $file ]]; then
          ''${EDITOR:-vim} "$file" +''${line:-1}
        fi
      }
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      # Ripgrep with fzf integration
      rgfzf() {
        if [ $# -eq 0 ]; then
          echo "Usage: rgfzf <search_pattern> [rg_options...]"
          return 1
        fi
        rg --color=always --line-number --no-heading --smart-case "''${@}" |
          fzf --ansi \
              --color "hl:-1:underline,hl+:-1:underline:reverse" \
              --delimiter : \
              --preview 'bat --color=always {1} --highlight-line {2}' \
              --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
              --bind 'enter:become(nvim {1} +{2})'
      }

      # Search and edit with ripgrep
      rge() {
        local file line
        read -r file line <<< $(rg --no-heading --line-number "''${1:-}" | fzf --delimiter=: --preview 'bat --color=always --line-range {2}: {1}' | cut -d: -f1,2)
        if [[ -n $file ]]; then
          ''${EDITOR:-vim} "$file" +''${line:-1}
        fi
      }
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      # Ripgrep with fzf integration
      function rgfzf
        if test (count $argv) -eq 0
          echo "Usage: rgfzf <search_pattern> [rg_options...]"
          return 1
        end
        rg --color=always --line-number --no-heading --smart-case $argv |
          fzf --ansi \
              --color "hl:-1:underline,hl+:-1:underline:reverse" \
              --delimiter : \
              --preview 'bat --color=always {1} --highlight-line {2}' \
              --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
              --bind 'enter:become(nvim {1} +{2})'
      end

      # Search and edit with ripgrep
      function rge
        set -l result (rg --no-heading --line-number $argv[1] | fzf --delimiter=: --preview 'bat --color=always --line-range {2}: {1}')
        if test -n "$result"
          set -l file (echo $result | cut -d: -f1)
          set -l line (echo $result | cut -d: -f2)
          $EDITOR $file +$line
        end
      end
    '';

    # Nushell integration with advanced functions
    programs.nushell.extraConfig = mkIf cfg.enableNushellIntegration ''
      # Ripgrep with structured output for Nushell
      def rgnu [pattern: string, ...args] {
        rg --json $pattern ...$args 
        | lines 
        | where $it != "" 
        | each { |line| $line | from json } 
        | where type == "match" 
        | select data.path.text data.line_number data.lines.text 
        | rename file line content
      }

      # Search files and get structured results
      def rgfiles [pattern?: string] {
        if ($pattern | is-empty) {
          rg --files | lines
        } else {
          rg --files | lines | where ($it | str contains $pattern)
        }
      }

      def rgfzf [pattern: string, ...args] {
        let results = (rg --color=always --line-number --no-heading --smart-case $pattern ...$args | complete)
        if ($results.exit_code == 0) {
          $results.stdout
          | ^fzf --ansi --color "hl:-1:underline,hl+:-1:underline:reverse" --delimiter ":" --preview "bat --color=always {1} --highlight-line {2}" --preview-window "up,60%,border-bottom,+{2}+3/3,~3"
        } else {
          print $"No matches found for pattern: ($pattern)"
        }
      }
      
      # Search and get file statistics
      def rgstats [pattern: string, ...args] {
        rg --stats $pattern ...$args | lines | parse "{key}: {value}" | where key != "" and value != ""
      }

      # Search with context and pretty formatting
      def rgcontext [pattern: string, --before (-B): int = 2, --after (-A): int = 2, ...args] {
        rg --before-context $before --after-context $after --pretty $pattern ...$args
      }

      # Search and group results by file type
      def rgbytype [pattern: string, ...args] {
        rg --json $pattern ...$args
        | lines
        | where $it != ""
        | each { |line| $line | from json }
        | where type == "match"
        | select data.path.text data.line_number data.lines.text
        | rename file line content
        | insert extension { |row| $row.file | path parse | get extension }
        | group-by extension
        | transpose type matches
        | insert count { |row| $row.matches | length }
        | select type count matches
      }

      # Count matches per file
      def rgcount [pattern: string, ...args] {
        rg --count-matches $pattern ...$args
        | lines
        | parse "{file}:{count}"
        | where count != "0"
        | update count { |row| $row.count | into int }
        | sort-by count --reverse
      }

      # Search in specific file types with Nushell filtering
      def rgt [type: string, pattern: string, ...args] {
        rg --type $type $pattern ...$args
      }

      # Advanced search with multiple patterns (OR logic)
      def rgor [...patterns] {
        let pattern_str = ($patterns | str join "|")
        rg $"($pattern_str)" --color=always
      }

      # Search and replace preview (dry run)
      def rgreplace [pattern: string, replacement: string, ...files] {
        if ($files | is-empty) {
          rg --passthru --color=always $pattern | rg --replace $replacement $pattern
        } else {
          $files | each { |file|
            print $"=== ($file) ==="
            rg --passthru --color=always $pattern $file | rg --replace $replacement $pattern
          }
        }
      }

      # Export ripgrep results to various formats
      def rgexport [pattern: string, format: string = "json", ...args] {
        match $format {
          "json" => { rg --json $pattern ...$args | lines | where $it != "" | each { |line| $line | from json } | where type == "match" },
          "csv" => { 
            rg --json $pattern ...$args 
            | lines 
            | where $it != "" 
            | each { |line| $line | from json } 
            | where type == "match" 
            | select data.path.text data.line_number data.lines.text 
            | rename file line content 
            | to csv
          },
          "table" => { 
            rg --json $pattern ...$args 
            | lines 
            | where $it != "" 
            | each { |line| $line | from json } 
            | where type == "match" 
            | select data.path.text data.line_number data.lines.text 
            | rename file line content 
            | table
          },
          _ => { print $"Unsupported format: ($format). Use json, csv, or table." }
        }
      }

      # Search with live preview (requires external tools)
      def rglive [pattern: string] {
        print $"Searching for: ($pattern)"
        print "Press Ctrl+C to stop"
        loop {
          clear
          let results = (rg --color=always --heading --line-number $pattern | complete)
          if ($results.exit_code == 0) {
            print $results.stdout
          } else {
            print "No matches found"
          }
          sleep 1sec
        }
      }
    '';
  };
}
