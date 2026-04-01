#!/usr/bin/env bash
set -euo pipefail

# Collect SSH host keys from all configured NixOS hosts
# Usage: ./collect-host-keys.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SSH_KEYS_DIR="$REPO_ROOT/ssh-keys"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# List of hosts to collect from
# Add/remove hosts as needed
HOSTS=(
  "router"
  "workstation"
  "homeserver"
  "attic-cache"
  "rustdesk"
)

log_info "Collecting SSH host keys from configured hosts..."

for host in "${HOSTS[@]}"; do
  OUTPUT_FILE="$SSH_KEYS_DIR/${host}-host-ed25519.pub"
  
  log_info "Collecting from $host..."
  
  if ssh -o ConnectTimeout=5 "$host" "cat /etc/ssh/ssh_host_ed25519_key.pub" > "$OUTPUT_FILE" 2>/dev/null; then
    log_info "✓ Saved ${host}-host-ed25519.pub"
    cat "$OUTPUT_FILE"
  else
    log_warn "✗ Failed to connect to $host or key not found"
    rm -f "$OUTPUT_FILE"
  fi
  
  echo
done

log_info "Done! Host keys saved to $SSH_KEYS_DIR/"
log_info "Next: Run ./generate-secrets-nix.sh to create secrets.nix for agenix"
