{ pkgs, ... }:
{
  security.sudo.package = pkgs.sudo-rs;
}
