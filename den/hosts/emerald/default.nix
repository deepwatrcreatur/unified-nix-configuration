{ lib, inputs, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "emerald";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/emerald
    ../../../users/deepwatrcreatur/aspects/developer.nix
    { programs.herdr.desktopApp.enable = true; }
  ];
  extraImports = [
    inputs.disko.nixosModules.disko
    inputs.nix-omarchy-screen-mirroring.nixosModules.default
    inputs.nix-omarchy-iphone-mirror.nixosModules.default
    ../../../hosts/nixos/emerald/disko.nix
    ../../../hosts/nixos/emerald/hardware-configuration.nix
    ../../../hosts/nixos/emerald/networking.nix
    ../../../modules/nixos/fish-interactive-bash-login.nix
    { custom.fishInteractiveShell.users = [ "deepwatrcreatur" ]; }
    ({ pkgs, lib, ... }: {
      services.omarchy-screen-mirroring.enable = true;
      services.omarchy-iphone-mirror.enable = true;
      environment.systemPackages = with pkgs; [
        omasnap
        flameshot
        google-chrome
        firefox
        vivaldi
      ];

      time.timeZone = "America/Toronto";
      i18n.defaultLocale = "en_CA.UTF-8";

      boot.loader.systemd-boot.enable = lib.mkDefault true;
      boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
      programs.nix-ld.enable = true;
      programs.linuxbrew = {
        enableSystemSetup = true;
        owner = "deepwatrcreatur";
      };
      programs.strata = {
        enable = true;
        defaultFileManager = true;
      };
    })
  ];
}
