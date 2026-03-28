# Auto-generated secrets.nix for agenix
# Manually normalized after replacing the old homeserver LXC.
let
  machineIdentity = import ./lib/agenix-machine-identities.nix;
  remoteBuilder = import ./lib/remote-builder.nix {};
  readPublicKey = path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile path);
  stableDeepwatrcreaturKey = readPublicKey ./ssh-keys/deepwatrcreatur-stable-identity.pub;
  stableRootKey = readPublicKey ./ssh-keys/root-stable-identity.pub;

  hosts = {
    attic-cache = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBMzmqOZ301fwZJVQI5KZ9+npuFs+3EvwKet4peLZeLv";
    gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjM16WJ9SUCs+moDo8QTTbbEJMd0EYZPGItC6oV4WiO root@nixos";
    homeserver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOo9lHhuHiT1rAF3RcFwSMYYtQvoheU4IxVsCRBKlPFI root@nixoslxc";
    pve-gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKneb67aN01m3ygkITF7BOU4YbKsPRZCErT/d5TVcquy";
    pve-lattitude = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOz/qnrymEHn6b057GKCOMCfB9fK28HkWmZ6MnXblVO2";
    pve-rog = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkWE8kICYI4rPsw/SWfEjOcBrKRk0DywrYSOFZkdlDX agenix-machine-identity pve-rog";
    pve-strix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAgSeJeuivBkeB92lG8Sup+fQl4AwfRWH3XlCJSMQ3j4";
    pve-tomahawk = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDjJqDjZBW8RisQsxPxSIY3GoJj4AM8wwqbqSbC6ygnY";
    rustdesk = "";
    workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFAzJUqDpasPy2B+vODDAZOdGJ/7DiZ1wWjbWkM1Bi8 root@workstation";
  };

  users = {
    # Single stable identity used across all hosts
    deepwatrcreatur = stableDeepwatrcreaturKey;
    # Stable root identity - private key auto-deployed via agenix
    root = stableRootKey;
  };

  # All NixOS hosts that should receive the root SSH key
  rootSshKeyHosts = [
    "authentik-host"
    "attic-cache"
    "gateway"
    "homeserver"
    "inference1"
    "inference2"
    "inference3"
    "podman"
    "workstation"
  ];

  # Single stable operator identity - same key deployed to all hosts
  operatorUsers = [
    users.deepwatrcreatur
  ];

  machineRecipients = hostName: let
    stable = machineIdentity.readPublicKey hostName;
    legacy = hosts.${hostName} or null;
  in
    if stable != null && stable != ""
    then [stable]
    else builtins.filter (key: key != null && key != "") [legacy];

  userOnlySecrets = operatorUsers;

  gatewayServiceSecrets = operatorUsers ++ machineRecipients "gateway";
  homeserverServiceSecrets = operatorUsers ++ machineRecipients "homeserver";
  authentikHostServiceSecrets = operatorUsers ++ machineRecipients "authentik-host";

  atticServiceSecrets = operatorUsers ++ machineRecipients "attic-cache";

  remoteBuilderClientSecrets =
    operatorUsers ++ builtins.concatLists (map machineRecipients remoteBuilder.supportedHosts);

  # All hosts that build from this repo should be able to use the attic cache
  atticClientHosts = [
    "authentik-host"
    "attic-cache"
    "gateway"
    "homeserver"
    "inference1"
    "inference2"
    "inference3"
    "podman"
    "pve-gateway"
    "pve-lattitude"
    "pve-rog"
    "pve-strix"
    "pve-tomahawk"
    "workstation"
    # TODO: Add hackintosh and macminim4 once their host keys are in the hosts list
  ];

  atticClientSecrets = operatorUsers ++ builtins.concatLists (map machineRecipients atticClientHosts);

  # Hosts that use the nix-ci.com paid cache service
  # Using same list as atticClientHosts - all NixOS hosts benefit from shared cache
  nixCiCacheHosts = atticClientHosts;

  nixCiCacheSecrets = operatorUsers ++ builtins.concatLists (map machineRecipients nixCiCacheHosts);

  githubTokenHosts = atticClientHosts;
  githubTokenSecrets = operatorUsers ++ builtins.concatLists (map machineRecipients githubTokenHosts);

  podmanServiceSecrets = operatorUsers ++ machineRecipients "podman";
in {
  # Service-scoped secrets
  "secrets-agenix/cloudflare-api-key.age".publicKeys = gatewayServiceSecrets;
  "secrets-agenix/cloudflare_ddns_API_token.age".publicKeys = gatewayServiceSecrets;
  "secrets-agenix/technitium-api-key.age".publicKeys = gatewayServiceSecrets;
  "secrets-agenix/tailscale-auth-key.age".publicKeys = gatewayServiceSecrets;
  "secrets-agenix/authentik-env.age".publicKeys = authentikHostServiceSecrets;
  "secrets-agenix/attic-client-token.age".publicKeys = atticClientSecrets;
  "secrets-agenix/attic-server-token.age".publicKeys = atticServiceSecrets;
  "secrets-agenix/attic-jwt-secret.age".publicKeys = atticServiceSecrets;
  "secrets-agenix/nix-remote-builder-key.age".publicKeys = remoteBuilderClientSecrets;
  "secrets-agenix/paperless-db-password.age".publicKeys = podmanServiceSecrets;
  "secrets-agenix/paperless-authentik-oidc.age".publicKeys = podmanServiceSecrets;
  "secrets-agenix/nightscout-api-secret.age".publicKeys = podmanServiceSecrets;
  "secrets-agenix/librelinkup-env.age".publicKeys = podmanServiceSecrets;

  # Operator/user secrets decrypted directly in Home Manager with the stable user key
  "secrets-agenix/github-token.age".publicKeys = githubTokenSecrets;
  "secrets-agenix/grok-api-key.age".publicKeys = userOnlySecrets;
  "secrets-agenix/openrouter-api-key.age".publicKeys = userOnlySecrets;
  "secrets-agenix/z-ai-api-key.age".publicKeys = userOnlySecrets;
  "secrets-agenix/opencode-zen-api-key.age".publicKeys = userOnlySecrets;
  "secrets-agenix/atuin-key-b64.age".publicKeys = userOnlySecrets;
  "secrets-agenix/oauth-creds.age".publicKeys = userOnlySecrets;
  "secrets-agenix/bitwarden-data.age".publicKeys = userOnlySecrets;
  "secrets-agenix/rclone-conf.age".publicKeys = userOnlySecrets;
  "secrets-agenix/proxmox-api-token.age".publicKeys = userOnlySecrets;

  # nix-ci.com cache authentication (netrc format)
  "secrets-agenix/nix-ci-netrc.age".publicKeys = nixCiCacheSecrets;

  # Stable root SSH key - deployed to /root/.ssh/id_ed25519 via agenix
  "secrets-agenix/root-ssh-key.age".publicKeys =
    operatorUsers ++ builtins.concatLists (map machineRecipients rootSshKeyHosts);
}
