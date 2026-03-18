{
  config,
  lib,
  ...
}:

{
  my.agenix.machineIdentity = {
    enable = lib.mkDefault false;
  };

  # System-wide agenix configuration
  # Secrets are decrypted at boot and placed in /run/agenix/
  age.identityPaths = lib.mkIf (!config.my.agenix.machineIdentity.enable) [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
}
