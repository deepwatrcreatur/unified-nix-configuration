#!/usr/bin/env bash
set -euo pipefail

# Generate secrets.nix from ssh-keys directory for agenix
# Usage: ./generate-secrets-nix.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SSH_KEYS_DIR="$REPO_ROOT/ssh-keys"
OUTPUT_FILE="$REPO_ROOT/secrets.nix"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }

log_info "Generating secrets.nix from $SSH_KEYS_DIR..."

# Start building the nix file
cat > "$OUTPUT_FILE" << 'EOF'
# Auto-generated secrets.nix for agenix
# DO NOT EDIT MANUALLY - regenerate with scripts/agenix/generate-secrets-nix.sh
let
  machineIdentity = import ./lib/agenix-machine-identities.nix;

  # System host keys (for system-level secrets)
  hosts = {
EOF

# Add host keys (pattern: {hostname}-host-ed25519.pub)
for keyfile in "$SSH_KEYS_DIR"/*-host-ed25519.pub; do
  if [[ -f "$keyfile" ]]; then
    filename=$(basename "$keyfile")
    hostname="${filename%-host-ed25519.pub}"
    key=$(cat "$keyfile")
    echo "    $hostname = \"$key\";" >> "$OUTPUT_FILE"
  fi
done

cat >> "$OUTPUT_FILE" << 'EOF'
  };
  
  # User keys (for user-level secrets in home-manager)
  users = {
EOF

# Add user keys (pattern: username@{hostname}-ed25519.pub, but we want unique users)
# Extract unique usernames
declare -A user_keys
for keyfile in "$SSH_KEYS_DIR"/*@*-ed25519.pub; do
  if [[ -f "$keyfile" ]]; then
    filename=$(basename "$keyfile")
    # Extract username before @
    username="${filename%%@*}"
    if [[ -z "${user_keys[$username]:-}" ]]; then
      # Use first key found for this user
      key=$(cat "$keyfile")
      user_keys[$username]="$key"
    fi
  fi
done

# Write unique user keys
for username in "${!user_keys[@]}"; do
  echo "    $username = \"${user_keys[$username]}\";" >> "$OUTPUT_FILE"
done

cat >> "$OUTPUT_FILE" << 'EOF'
  };

  operatorUserNames = [
    "deepwatrcreatur"
  ];

  operatorUsers =
    builtins.concatLists (
      map (name: if builtins.hasAttr name users then [ users.${name} ] else [ ]) operatorUserNames
    );

  machineRecipients =
    hostName:
    let
      stable = machineIdentity.readPublicKey hostName;
      legacy = hosts.${hostName} or null;
    in
    if stable != null && stable != "" then
      [ stable ]
    else
      builtins.filter (key: key != null && key != "") [ legacy ];
in
{
  # System-level secrets
  "cloudflare-api-key.age".publicKeys = operatorUsers ++ machineRecipients "gateway";
  "technitium-api-key.age".publicKeys = operatorUsers ++ machineRecipients "gateway";
  
  # User-level secrets
  "github-token.age".publicKeys = operatorUsers;
  "grok-api-key.age".publicKeys = operatorUsers;
  "openrouter-api-key.age".publicKeys = operatorUsers;
  "atuin-key.age".publicKeys = operatorUsers;
  
  # Add more secrets as needed...
}
EOF

log_info "✓ Generated $OUTPUT_FILE"
log_info "Review the file and adjust secret definitions as needed"
log_info "Next: Add agenix to flake.nix inputs and start migration"
