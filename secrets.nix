# Auto-generated secrets.nix for agenix
# Manually normalized after replacing the old homeserver LXC.
let
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
    deepwatrcreatur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6kog9oZnpZtFz2nqM5na6lriJKvjU31CF82mcTfvhe deepwatrcreatur@gmail.com";
    "deepwatrcreatur-homeserver" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBJ4DIw7ZaUAUVUF7GcEwEA8dOEaKtJ3SsVw2MBFV/H4 deepwatrcreatur@homeserver";
    root = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ+Rnj2TmFnoT8eygCClp/aOEzTnJgalIe1HGPWQkGL+ root@attic-cache";
    "root-homeserver" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBi+OJR+l/cO+Kf2WuCjKw9yLlcvqTaOb/KkolX+qgh root@homeserver";
  };

  allHosts = builtins.filter (key: key != "") (builtins.attrValues hosts);
  allUsers = builtins.attrValues users;
  allKeys = allHosts ++ allUsers;
in
{
  "secrets-agenix/cloudflare-api-key.age".publicKeys = [ hosts.gateway hosts.homeserver ] ++ allUsers;
  "secrets-agenix/technitium-api-key.age".publicKeys = [ hosts.gateway hosts.workstation ] ++ allUsers;
  "secrets-agenix/attic-client-token.age".publicKeys = [ hosts.attic-cache hosts.workstation ] ++ allUsers;
  "secrets-agenix/attic-server-token.age".publicKeys = [ hosts.attic-cache ] ++ allUsers;
  "secrets-agenix/attic-jwt-secret.age".publicKeys = [ hosts.attic-cache ] ++ allUsers;

  "secrets-agenix/github-token.age".publicKeys = allKeys;
  "secrets-agenix/grok-api-key.age".publicKeys = allKeys;
  "secrets-agenix/openrouter-api-key.age".publicKeys = allKeys;
  "secrets-agenix/z-ai-api-key.age".publicKeys = allKeys;
  "secrets-agenix/opencode-zen-api-key.age".publicKeys = allKeys;
  "secrets-agenix/atuin-key-b64.age".publicKeys = allKeys;
  "secrets-agenix/oauth-creds.age".publicKeys = allKeys;
  "secrets-agenix/bitwarden-data.age".publicKeys = allKeys;
  "secrets-agenix/rclone-conf.age".publicKeys = allKeys;
  "secrets-agenix/cloudflare_ddns_API_token.age".publicKeys = allKeys;
  "secrets-agenix/proxmox-api-token.age".publicKeys = allKeys;
}
