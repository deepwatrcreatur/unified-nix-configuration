{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myModules.specializations.safeMode;
  userName = config.host.primaryUser or "deepwatrcreatur";
in
{
  options.myModules.specializations.safeMode = {
    enable = lib.mkEnableOption "safe-mode recovery specialization";
  };

  config = lib.mkIf cfg.enable {
    specialisation.safemode.configuration = {
      system.nixos.tags = [ "safemode-tty" ];

      # ---------------------------------------------------------
      # 1. Kill complex Wayland compositors and display managers
      # ---------------------------------------------------------
      services.greetd.enable = lib.mkForce false;
      services.displayManager.sddm.enable = lib.mkForce false;
      services.displayManager.gdm.enable = lib.mkForce false;
      services.xserver.displayManager.lightdm.enable = lib.mkForce false;
      services.displayManager.cosmic-greeter.enable = lib.mkForce false;
      services.displayManager.autoLogin.enable = lib.mkForce false;

      services.desktopManager.cosmic.enable = lib.mkForce false;
      services.desktopManager.gnome.enable = lib.mkForce false;
      services.desktopManager.plasma6.enable = lib.mkForce false;
      services.xserver.desktopManager.xfce.enable = lib.mkForce false;
      programs.hyprland.enable = lib.mkForce false;
      programs.niri.enable = lib.mkForce false;

      # ---------------------------------------------------------
      # 2. Minimal X11 IceWM via startx
      # ---------------------------------------------------------
      services.xserver = {
        enable = lib.mkForce true;
        windowManager.icewm.enable = lib.mkForce true;
        displayManager.startx = {
          enable = lib.mkForce true;
          generateScript = lib.mkForce true;
          extraCommands = ''
            ${pkgs.xrandr}/bin/xrandr --auto || true
          '';
        };
      };

      home-manager.users.${userName} =
        { pkgs, ... }:
        {
          home.file.".xinitrc" = {
            text = ''
              #!/bin/sh
              # Auto-detect and enable all connected monitors at preferred resolution
              ${pkgs.xrandr}/bin/xrandr --auto || true

              # Launch IceWM
              exec ${pkgs.icewm}/bin/icewm-session
            '';
            executable = true;
          };

          home.shellAliases = {
            start-icewm = "startx";
          };
        };

      # ---------------------------------------------------------
      # 3. Force standard shell (bash), standard terminal (xterm), and basic editor (nano/vim)
      # ---------------------------------------------------------
      users.users.${userName}.shell = lib.mkForce pkgs.bashInteractive;
      users.users.root.shell = lib.mkForce pkgs.bashInteractive;
      users.defaultUserShell = lib.mkForce pkgs.bashInteractive;

      environment.variables = {
        EDITOR = lib.mkForce "nano";
        VISUAL = lib.mkForce "nano";
        TERMINAL = lib.mkForce "xterm";
      };

      # ---------------------------------------------------------
      # 4. Emergency survival toolkit
      # ---------------------------------------------------------
      environment.systemPackages = with pkgs; [
        # Recovery & filesystem tools
        parted
        btrfs-progs
        dosfstools
        pciutils
        usbutils

        # Visual CLI / disk inspection
        mc
        ncdu
        htop
        killall

        # Core editors & utilities
        nano
        vim
        curl
        wget
        git
        networkmanager

        # Minimal GUI & terminal
        xterm
        xfce4-terminal
        icewm
        xrandr
      ];
    };
  };
}
