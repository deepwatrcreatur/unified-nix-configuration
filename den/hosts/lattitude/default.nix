# den/hosts/lattitude/default.nix
{ lib, inputs, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "lattitude";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/lattitude
  ];
  extraImports = [
    inputs.disko.nixosModules.disko
    ../../../hosts/nixos/lattitude/disko.nix
    ../../../hosts/nixos/lattitude/hardware-configuration.nix
    ../../../hosts/nixos/lattitude/networking.nix
    ({ pkgs, lib, ... }: {
      environment.systemPackages = with pkgs; [
        # Explicitly requested:
        google-chrome
        firefox
        vivaldi
        thunderbird
        rclone

        # Suitable lightweight browsers:
        epiphany
        qutebrowser

        # Media & Kiosk utilities:
        mpv
        inputs.nightscout-tui.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      # zram swap to mitigate slow 5400 RPM mechanical disk bottlenecks
      zramSwap.enable = true;

      time.timeZone = "America/Toronto";
      i18n.defaultLocale = "en_CA.UTF-8";

      boot.loader.systemd-boot.enable = lib.mkDefault true;
      boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

      my.agenix.machineIdentity.enable = true;
      my.root-ssh-identity.enable = lib.mkForce false;

      # Kiosk power settings: keep laptop display awake 24/7 without suspend or blanking
      services.logind = {
        lidSwitch = "ignore";
        lidSwitchDocked = "ignore";
        lidSwitchExternalPower = "ignore";
        powerKey = "poweroff";
        settings.Login = {
          IdleAction = "ignore";
          IdleActionSec = "0";
        };
      };
      systemd.targets.sleep.enable = false;
      systemd.targets.suspend.enable = false;
      systemd.targets.hibernate.enable = false;
      systemd.targets.hybrid-sleep.enable = false;

      system.stateVersion = "26.05";
    })
  ];
}
