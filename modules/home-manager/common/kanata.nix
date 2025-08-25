# kanata.nix - Home Manager module for caps lock -> escape
{ config, lib, pkgs, ... }:

let
  kanataConfig = ''
    (defsrc
      caps
    )

    (deflayer default
      esc
    )
  '';
in
{
  services.kanata = {
    enable = true;
    keyboards.default = {
      config = kanataConfig;
    };
  };
}
