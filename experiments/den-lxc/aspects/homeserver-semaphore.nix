{ ... }:
{ inputs, ... }:
{
  imports = [
    inputs.nix-semaphore.nixosModules.default
  ];

  services.semaphore = {
    enable = true;
    openFirewall = true;
    host = "http://homeserver:3000";
  };
}
