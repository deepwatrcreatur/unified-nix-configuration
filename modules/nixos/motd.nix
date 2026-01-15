{
  config,
  lib,
  ...
}:

let
  host = config.networking.hostName;

  text = ''
    Host: ${host}

    Repo: ~/flakes/unified-nix-configuration
    Proxmox repo: /root/flakes/unified-nix-configuration

    Useful:
      - motd            (live status)
      - nh os switch -H ${host} -f ~/flakes/unified-nix-configuration
  '';

in
{
  environment.etc."motd".text = lib.mkForce text;
}
