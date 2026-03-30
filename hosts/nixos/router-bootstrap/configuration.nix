{ ... }:
{
  imports = [
    ../../../modules/nixos/bootstrap/base.nix
  ];

  networking.hostName = "router-bootstrap";
}
