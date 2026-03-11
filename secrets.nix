# Auto-generated secrets.nix for agenix
# DO NOT EDIT MANUALLY - regenerate with scripts/agenix/generate-secrets-nix.sh
let
  # System host keys (for system-level secrets)
  hosts = {
    gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjM16WJ9SUCs+moDo8QTTbbEJMd0EYZPGItC6oV4WiO root@nixos";
    workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFAzJUqDpasPy2B+vODDAZOdGJ/7DiZ1wWjbWkM1Bi8 root@workstation";
  };
  
  # User keys (for user-level secrets in home-manager)
  users = {
    deepwatrcreatur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6kog9oZnpZtFz2nqM5na6lriJKvjU31CF82mcTfvhe deepwatrcreatur@gmail.com";
    root = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ+Rnj2TmFnoT8eygCClp/aOEzTnJgalIe1HGPWQkGL+ root@attic-cache";
  };
  
  # Convenience groups
  allHosts = builtins.attrValues hosts;
  allUsers = builtins.attrValues users;
  allKeys = allHosts ++ allUsers;
in
{
  # System-level secrets
  "secrets-agenix/cloudflare-api-key.age".publicKeys = [ hosts.gateway hosts.homeserver ] ++ allUsers;
  "secrets-agenix/technitium-api-key.age".publicKeys = [ hosts.gateway hosts.workstation ] ++ allUsers;
  
  # User-level secrets (testing migration)
  "secrets-agenix/github-token.age".publicKeys = allKeys;
  "secrets-agenix/grok-api-key.age".publicKeys = allKeys;
  "secrets-agenix/openrouter-api-key.age".publicKeys = allKeys;
  "secrets-agenix/atuin-key.age".publicKeys = allKeys;
  
  # Add more secrets as needed...
}
