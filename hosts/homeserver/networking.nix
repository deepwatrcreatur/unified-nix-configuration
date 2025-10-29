{ config, lib, ... }:

{
  imports = [
    ../../../modules/nixos/networking.nix
  ];

  networking.hostName = "homeserver";

  networking.firewall = {
    allowedTCPPorts = [ 22 5201 ];
    allowedUDPPorts = [ 53 ];
  };

  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];
}
