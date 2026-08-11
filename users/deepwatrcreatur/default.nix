{
  config,
  pkgs,
  lib,
  inputs,
  hostName ? "",
  isDesktop ? false,
  ...
}:
let
  inherit (lib) optionals;
  repoName = builtins.baseNameOf (toString ../..);

  desktopModules = [
    {
      type = "custom";
      format = "DESKTOP";
      outputColor = "cyan";
    }
    {
      type = "de";
      key = "󰧨 DE";
      keyColor = "cyan";
      keyWidth = 16;
    }
    {
      type = "wm";
      key = "󱂬 WM";
      keyColor = "cyan";
      keyWidth = 16;
    }
    {
      type = "display";
      key = "󰍹 Display";
      keyColor = "cyan";
      keyWidth = 16;
      compactType = "original-with-refresh-rate";
      format = "{width}x{height} @ {refresh-rate} Hz";
    }
    {
      type = "terminal";
      key = " Terminal";
      keyColor = "cyan";
      keyWidth = 16;
      format = "{pretty-name}";
    }
    {
      type = "terminalfont";
      key = "󰛖 Font";
      keyColor = "cyan";
      keyWidth = 16;
      format = "{name}{?size} [{size}]{?}";
    }
    {
      type = "localip";
      key = "󰩠 Local IP";
      keyColor = "cyan";
      keyWidth = 16;
      compact = true;
    }
  ];

  headlessModules = [
    {
      type = "custom";
      format = "ACCESS";
      outputColor = "cyan";
    }
    {
      type = "shell";
      key = "󰆍 Shell";
      keyColor = "cyan";
      keyWidth = 16;
      format = "{pretty-name}{?version} [v{version}]{?}";
    }
    {
      type = "terminal";
      key = " Terminal";
      keyColor = "cyan";
      keyWidth = 16;
      format = "{pretty-name}";
    }
    {
      type = "localip";
      key = "󰩠 Local IP";
      keyColor = "cyan";
      keyWidth = 16;
      compact = true;
    }
  ];
in
{
  imports = [
    # System-level secrets are handled by agenix at /run/agenix/
    # User-level SOPS secrets are handled as a legacy fallback in user-secrets.nix
    ../../modules/home-manager/user-secrets.nix
    ./rbw.nix
    ./env.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/bitwarden-cli.nix
    ../../modules/home-manager/rclone-scripts.nix
    ../../modules/home-manager
    ../../modules/home-manager/common/cmux-tui.nix
    ../../modules/home-manager/fastfetch.nix
  ];

  programs.bitwarden-cli = {
    enable = true;
  };

  programs.zellij-vivid-rounded = {
    enable = true;
  };

  programs.fastfetch-custom = {
    enable = true;
  };

  programs.rclone-scripts.secretsPath = ./secrets;

  services.user-secrets = {
    enable = true;
    secretsPath = ./secrets;
  };

  programs.cmux-tui.enable = true;

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  home.file.".gnupg/public-key.asc" = {
    source = ./gpg-public-key.asc; # Remove toString, just use the path directly
  };
}
