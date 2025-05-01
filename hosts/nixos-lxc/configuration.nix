{ config, pkgs, ... }:

{
  imports = [  ];
  services.getty.autologinUser = "root";
  services.getty.enable = true;
  services.getty.tty = "console";

  environment.shells = with pkgs; [ bashInteractive ];

}
