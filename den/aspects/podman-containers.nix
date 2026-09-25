# den/aspects/podman-containers.nix
# Backward-compatibility aspect: aggregates podman-base and all individual container service aspects.
{ ... }:
{ ... }:
{
  imports = [
    ./podman-base.nix
    ./service-plex.nix
    ./service-nightscout.nix
    ./service-paperless.nix
    ./service-librelinkup.nix
    ./service-scrypted.nix
    ./service-homeassistant.nix
    ./service-netalertx.nix
    ./service-graylog.nix
  ];
}
