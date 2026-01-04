# hosts/macminim4/nix-store-uuid.nix
{ config, lib, ... }:

{
  custom.nix-mount = {
    enable = true;
    uuid = "B79433EC-DBA7-4BAB-949C-332CB282B0A9";
  };
}
