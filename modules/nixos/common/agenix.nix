{
  config,
  pkgs,
  lib,
  ...
}:

{
  # System-wide agenix configuration
  # Secrets are decrypted at boot and placed in /run/agenix/
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
  ];
}
