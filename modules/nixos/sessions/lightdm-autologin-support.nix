{ lib, ... }:

{
  services.xserver.enable = lib.mkDefault true;

  services.xserver.autoRepeatDelay = lib.mkDefault 300;
  services.xserver.autoRepeatInterval = lib.mkDefault 40;

  services.xserver.displayManager.lightdm.enable = lib.mkDefault true;

  services.displayManager.autoLogin = {
    enable = lib.mkDefault true;
    user = lib.mkDefault "deepwatrcreatur";
  };
}
