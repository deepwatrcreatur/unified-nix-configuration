# den/aspects/t3code.nix
# T3 Code - Agentic AI Coding GUI Harness by Theo Browne (@t3dotgg)
{ ... }:
{ lib, ... }:
{
  imports = [
    ../../modules/nixos/t3code.nix
  ];

  modules.desktop.apps.t3code = {
    enable = lib.mkDefault true;
    openFirewall = lib.mkDefault true;
  };
}
