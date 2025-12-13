{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.homebrew;

  # Essential tools that brew needs
  brewDeps = with pkgs; [
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    git
    openssh
    curl
    gnutar
    gzip
    xz
    gcc
    gnumake
    patch
    diffutils
  ];

  # Create a directory with symlinks to all essential binaries
  brewToolsDir = pkgs.symlinkJoin {
    name = "brew-tools";
    paths = brewDeps;
  };
in
{
  options.programs.homebrew = {
    enable = mkEnableOption "Homebrew package manager for Linux";

    brewPrefix = mkOption {
      type = types.str;
      default = "/home/linuxbrew/.linuxbrew";
      description = "Path where Homebrew is installed";
    };

    brews = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of Homebrew formulae to install";
    };

    casks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of Homebrew casks to install (if supported on Linux)";
    };

    taps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of Homebrew taps to add";
    };

    onActivation = {
      cleanup = mkOption {
        type = types.enum [
          "none"
          "uninstall"
          "zap"
        ];
        default = "none";
        description = "Cleanup strategy for Homebrew packages";
      };

      autoUpdate = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to auto-update Homebrew on activation";
      };

      upgrade = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to upgrade Homebrew packages on activation";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = brewDeps ++ [
      pkgs.curl
      pkgs.git
      pkgs.gcc
    ];

    # Add Homebrew to PATH and set environment variables
    environment.variables = {
      HOMEBREW_PREFIX = cfg.brewPrefix;
      HOMEBREW_CELLAR = "${cfg.brewPrefix}/Cellar";
      HOMEBREW_REPOSITORY = "${cfg.brewPrefix}/Homebrew";
      MANPATH = "${cfg.brewPrefix}/share/man:";
      INFOPATH = "${cfg.brewPrefix}/share/info:";
    };

    environment.extraInit = ''
      if [ -f "${cfg.brewPrefix}/bin/brew" ]; then
        eval "$(${cfg.brewPrefix}/bin/brew shellenv)"
      fi
    '';

    # Add Homebrew bin to PATH
    environment.sessionVariables.PATH = [
      "${cfg.brewPrefix}/bin"
      "${cfg.brewPrefix}/sbin"
    ];

    # Create symlinks in /usr/bin for tools that brew expects
    # This is needed because brew's internal scripts look for tools in standard locations
    system.activationScripts.brewSymlinks = {
      text = ''
        # Create /usr/bin if it doesn't exist
        mkdir -p /usr/bin
        
        # Create symlinks for essential tools brew needs
        for tool in cp ln mv rm mkdir rmdir cat ls chmod chown touch head tail tr cut sort uniq wc basename dirname readlink realpath mktemp env test expr printf install stat date sleep tee xargs; do
          if [ ! -e "/usr/bin/$tool" ] && [ -e "${pkgs.coreutils}/bin/$tool" ]; then
            ln -sf "${pkgs.coreutils}/bin/$tool" "/usr/bin/$tool"
          fi
        done
        
        # Git and SSH
        if [ ! -e "/usr/bin/git" ]; then
          ln -sf "${pkgs.git}/bin/git" "/usr/bin/git"
        fi
        if [ ! -e "/usr/bin/ssh" ]; then
          ln -sf "${pkgs.openssh}/bin/ssh" "/usr/bin/ssh"
        fi
        
        # Other essential tools
        if [ ! -e "/usr/bin/find" ]; then
          ln -sf "${pkgs.findutils}/bin/find" "/usr/bin/find"
        fi
        if [ ! -e "/usr/bin/xargs" ] && [ -e "${pkgs.findutils}/bin/xargs" ]; then
          ln -sf "${pkgs.findutils}/bin/xargs" "/usr/bin/xargs"
        fi
        if [ ! -e "/usr/bin/grep" ]; then
          ln -sf "${pkgs.gnugrep}/bin/grep" "/usr/bin/grep"
        fi
        if [ ! -e "/usr/bin/sed" ]; then
          ln -sf "${pkgs.gnused}/bin/sed" "/usr/bin/sed"
        fi
        if [ ! -e "/usr/bin/awk" ]; then
          ln -sf "${pkgs.gawk}/bin/awk" "/usr/bin/awk"
        fi
        if [ ! -e "/usr/bin/tar" ]; then
          ln -sf "${pkgs.gnutar}/bin/tar" "/usr/bin/tar"
        fi
        if [ ! -e "/usr/bin/gzip" ]; then
          ln -sf "${pkgs.gzip}/bin/gzip" "/usr/bin/gzip"
        fi
        if [ ! -e "/usr/bin/curl" ]; then
          ln -sf "${pkgs.curl}/bin/curl" "/usr/bin/curl"
        fi
        if [ ! -e "/usr/bin/make" ]; then
          ln -sf "${pkgs.gnumake}/bin/make" "/usr/bin/make"
        fi
        if [ ! -e "/usr/bin/patch" ]; then
          ln -sf "${pkgs.patch}/bin/patch" "/usr/bin/patch"
        fi
        if [ ! -e "/usr/bin/diff" ]; then
          ln -sf "${pkgs.diffutils}/bin/diff" "/usr/bin/diff"
        fi
      '';
      deps = [ ];
    };
  };
}
