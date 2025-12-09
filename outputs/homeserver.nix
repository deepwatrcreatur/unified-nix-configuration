# outputs/homeserver.nix
{ helpers, ... }:
{
  nixosConfigurations.homeserver = helpers.mkNixosSystem {
    system = "x86_64-linux";
    hostPath = ../hosts/homeserver;
    extraModules = [
      ../hosts/nixos/default.nix
    ]
    ++ (
      if builtins.pathExists /etc/nixos/local-secrets.nix then [ /etc/nixos/local-secrets.nix ] else [ ]
    );
  };
}
