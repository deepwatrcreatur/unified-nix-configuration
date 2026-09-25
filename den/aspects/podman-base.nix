# den/aspects/podman-base.nix
# Base Podman container runtime aspect.
# Configures the core daemon, auto-prune, and systemd OCI backend without individual container services.
{ ... }:
{ ... }:
{
  imports = [
    ../../modules/nixos/container-stack.nix
  ];

  # Enable Podman with settings
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  # Declarative OCI containers managed by systemd
  virtualisation.oci-containers = {
    backend = "podman";
  };
}
