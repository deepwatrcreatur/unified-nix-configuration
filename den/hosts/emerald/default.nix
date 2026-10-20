{ lib, inputs, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "emerald";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/emerald
  ];
  extraImports = [
    inputs.disko.nixosModules.disko
    inputs.nix-omarchy-screen-mirroring.nixosModules.default
    inputs.nix-omarchy-iphone-mirror.nixosModules.default
    ../../../hosts/nixos/emerald/disko.nix
    ../../../hosts/nixos/emerald/hardware-configuration.nix
    ../../../hosts/nixos/emerald/networking.nix
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
      # Prevent AMD Raphael iGPU ring timeouts (gfx_0.1.0 timeout) during GPU power state transitions.
      # Note: amdgpu.gfxoff=0 is not a valid module param; GFXOFF is controlled by bit 15 (0x8000) of ppfeaturemask.
      # Masking 0x8000 out of default 0xfff7bfff yields 0xfff73fff. Also disable runtime PM drops.
      boot.kernelParams = [
        "amdgpu.ppfeaturemask=0xfff73fff"
        "amdgpu.runpm=0"
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
