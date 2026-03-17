# Auto-generated secrets.nix for agenix
# Manually normalized after replacing the old homeserver LXC.
let
  remoteBuilder = import ./lib/remote-builder.nix;

  hosts = {
    attic-cache = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBMzmqOZ301fwZJVQI5KZ9+npuFs+3EvwKet4peLZeLv";
    gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjM16WJ9SUCs+moDo8QTTbbEJMd0EYZPGItC6oV4WiO root@nixos";
    homeserver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOo9lHhuHiT1rAF3RcFwSMYYtQvoheU4IxVsCRBKlPFI root@nixoslxc";
    pve-gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKneb67aN01m3ygkITF7BOU4YbKsPRZCErT/d5TVcquy";
    pve-lattitude = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOz/qnrymEHn6b057GKCOMCfB9fK28HkWmZ6MnXblVO2";
    pve-strix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgSeJeuivBkeB92lG8Sup+fQl4AwfRWH3XlCJSMQ3j4";
    pve-tomahawk = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDjJqDjZBW8RisQsxPxSIY3GoJj4AM8wwqbqSbC6ygnY";
    rustdesk = "";
    workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFAzJUqDpasPy2B+vODDAZOdGJ/7DiZ1wWjbWkM1Bi8 root@workstation";
  };

  users = {
    deepwatrcreatur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIB4ELcnxIV0zujIJ4EPubU5nkKPV7G8pZ3tDDjZ6pXI deepwatrcreatur@gmail.com";
    "deepwatrcreatur-homeserver" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJ4DIw7ZaUAUVUF7GcEwEA8dOEaKtJ3SsVw2MBFV/H4 deepwatrcreatur@homeserver";
    root = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ+Rnj2TmFnoT8eygCClp/aOEzTnJgalIe1HGPWQkGL+ root@attic-cache";
    "root-homeserver" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBi+OJR+l/cO+Kf2WuCjKw9yLlcvqTaOb/KkolX+qgh root@homeserver";
  };

  operatorUsers = [
    users.deepwatrcreatur
  ];

  userOnlySecrets = operatorUsers;

  gatewayServiceSecrets = operatorUsers ++ [
    hosts.gateway
  ];

  atticServiceSecrets = operatorUsers ++ [
    hosts.attic-cache
  ];

  remoteBuilderClientSecrets = operatorUsers ++ map (hostName: hosts.${hostName}) remoteBuilder.supportedHosts;

  # All hosts that build from this repo should be able to use the attic cache
  atticClientSecrets = operatorUsers ++ [
    hosts.attic-cache
    hosts.gateway
    hosts.homeserver
    hosts.pve-gateway
    hosts.pve-lattitude
    hosts.pve-strix
    hosts.pve-tomahawk
    hosts.workstation
    # TODO: Add hackintosh and macminim4 once their host keys are in the hosts list
  ];
in
{
  # Service-scoped secrets
  "secrets-agenix/cloudflare-api-key.age".publicKeys = gatewayServiceSecrets;
  "secrets-agenix/cloudflare_ddns_API_token.age".publicKeys = gatewayServiceSecrets;
  "secrets-agenix/technitium-api-key.age".publicKeys = gatewayServiceSecrets;
  "secrets-agenix/attic-client-token.age".publicKeys = atticClientSecrets;
  "secrets-agenix/attic-server-token.age".publicKeys = atticServiceSecrets;
  "secrets-agenix/attic-jwt-secret.age".publicKeys = atticServiceSecrets;
  "secrets-agenix/nix-remote-builder-key.age".publicKeys = remoteBuilderClientSecrets;

  # Operator/user secrets decrypted directly in Home Manager with the stable user key
  "secrets-agenix/github-token.age".publicKeys = userOnlySecrets;
  "secrets-agenix/grok-api-key.age".publicKeys = userOnlySecrets;
  "secrets-agenix/openrouter-api-key.age".publicKeys = userOnlySecrets;
  "secrets-agenix/z-ai-api-key.age".publicKeys = userOnlySecrets;
  "secrets-agenix/opencode-zen-api-key.age".publicKeys = userOnlySecrets;
  "secrets-agenix/atuin-key-b64.age".publicKeys = userOnlySecrets;
  "secrets-agenix/oauth-creds.age".publicKeys = userOnlySecrets;
  "secrets-agenix/bitwarden-data.age".publicKeys = userOnlySecrets;
  "secrets-agenix/rclone-conf.age".publicKeys = userOnlySecrets;
  "secrets-agenix/proxmox-api-token.age".publicKeys = userOnlySecrets;
}
