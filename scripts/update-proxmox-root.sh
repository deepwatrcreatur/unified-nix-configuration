#!/usr/bin/env bash
# Script to update proxmox-root with the bash PATH fix
# Run this on pve-lattitude (10.10.11.47)

set -euo pipefail

HOST="${1:-10.10.11.47}"
REPO="${2:-/root/flakes/unified-nix-configuration}"

echo "🔄 Updating proxmox-root configuration on $HOST..."

# SSH into host and rebuild
ssh root@$HOST << EOF
  echo "📥 Pulling latest changes..."
  cd $REPO
  git pull

  echo "🔨 Activating home-manager with fix..."
  # Source Nix environment and run activation
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  nix run nixpkgs#home-manager -- switch --flake .#proxmox-root
EOF

echo "✅ Configuration updated successfully!"
echo ""
echo "🔍 To verify, SSH into the host and run:"
echo "   which atuin"
echo "   atuin --version"
