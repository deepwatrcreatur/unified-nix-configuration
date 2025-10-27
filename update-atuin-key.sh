#!/bin/bash
# Script to update atuin key in encrypted secrets

set -e

echo "Updating atuin key..."
echo "Enter your atuin key (or press Enter to generate a new one):"
read -r ATUIN_KEY

if [ -z "$ATUIN_KEY" ]; then
    echo "Generating new atuin key..."
    # If you have atuin installed, you can generate a key like this:
    # ATUIN_KEY=$(atuin key)
    # For now, we'll use a placeholder - replace this with your actual key
    echo "Please set ATUIN_KEY to your actual atuin key"
    exit 1
fi

# Create temporary YAML file
cat > /tmp/atuin-key.yaml << EOF
# Atuin encryption key - shared between users
atuin_key: "$ATUIN_KEY"
EOF

# Encrypt the file
cd /Users/deepwatrcreatur/unified-nix-configuration
sops --encrypt /tmp/atuin-key.yaml > secrets/atuin-key.enc

# Clean up
rm /tmp/atuin-key.yaml

echo "Atuin key updated successfully!"
echo "You can now rebuild your system configuration."
