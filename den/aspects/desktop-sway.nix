# den/aspects/desktop-sway.nix
# Lightweight Sway tiling window manager aspect suitable for low-power kiosk and desktop nodes
{
  primaryUser ? "deepwatrcreatur",
  ...
}:
{
  pkgs,
  lib,
  config,
  ...
}:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      foot
      wmenu
      wl-clipboard
      mako
      i3status
      brightnessctl
      playerctl
      pavucontrol
    ];
  };

  # Hardware graphics & video acceleration (Mesa radeonsi VA-API / OpenGL)
  hardware.graphics = {
    enable = lib.mkDefault true;
    enable32Bit = lib.mkDefault true;
  };

  # Audio via PipeWire
  services.pipewire = {
    enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };

  # Polkit authentication agent
  security.polkit.enable = true;

  # XDG Desktop Portals for Wayland (wlr + gtk)
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [ "wlr" "gtk" ];
  };

  # Greetd login manager: auto-login into sway session
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.sway}/bin/sway";
        user = primaryUser;
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd ${pkgs.sway}/bin/sway";
        user = "greeter";
      };
    };
  };

  users.users.${primaryUser} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "render"
      "input"
      "audio"
    ];
  };

  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    extraGroups = [
      "video"
      "input"
    ];
  };
  users.groups.greeter = { };

  # Prevent conflicts with other display managers
  services.displayManager.gdm.enable = lib.mkDefault false;
  services.displayManager.sddm.enable = lib.mkDefault false;
  services.xserver.displayManager.lightdm.enable = lib.mkDefault false;

  # Home Manager Sway configuration
  home-manager.sharedModules = [
    (
      { config, lib, pkgs, ... }:
      {
        wayland.windowManager.sway = {
          enable = true;
          package = null; # Use system package from programs.sway
          config = rec {
            modifier = "Mod4"; # Super key
            terminal = "${pkgs.foot}/bin/foot";
            menu = "${pkgs.wmenu}/bin/wmenu-run";
            bars = [
              {
                position = "top";
                statusCommand = "${pkgs.i3status}/bin/i3status";
                fonts = {
                  names = [ "monospace" ];
                  size = 10.0;
                };
              }
            ];
            window = {
              titlebar = false;
              border = 2;
            };
            gaps = {
              inner = 4;
              outer = 4;
            };
          };
          extraConfig = ''
            # Output power management / idle
            exec ${pkgs.swayidle}/bin/swayidle -w \
              timeout 600 '${pkgs.sway}/bin/swaymsg "output * power off"' \
              resume '${pkgs.sway}/bin/swaymsg "output * power on"'
          '';
        };

        programs.foot = {
          enable = true;
          settings = {
            main = {
              font = "monospace:size=11";
            };
          };
        };
      }
    )
  ];
}
