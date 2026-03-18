pkgs:
let
  supportedHosts = [
    "gateway"
    "homeserver"
    "workstation"
  ];
in
{
  inherit supportedHosts;

  keyPath =
    if pkgs.stdenv.isDarwin then
      "/var/root/.ssh/nix-remote"
    else
      "/root/.ssh/nix-remote";

  canUse = hostName: hostName != "attic-cache" && builtins.elem hostName supportedHosts;
}
