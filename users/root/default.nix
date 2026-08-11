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
    ./sops.nix # <--- Temporarily disabled sops configuration
    ./git.nix # <--- Import git configuration
    ./env.nix
    ../../modules/home-manager/git.nix # Keep this import if it provides other common git modules
    ../../modules/home-manager/git-ssh-signing.nix
    ../../modules/home-manager
    ../../modules/home-manager/fastfetch.nix
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  # Allow root to manage Home Manager
  programs.home-manager.enable = true;

  programs.zellij-vivid-rounded = {
    enable = true;
  };

  programs.fastfetch-custom = {
    enable = true;
  };
}
