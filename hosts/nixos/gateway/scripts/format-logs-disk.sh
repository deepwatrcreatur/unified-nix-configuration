#!/usr/bin/env bash
# Script to format /dev/sdb for gateway logs
# Run this manually on the gateway machine

set -euo pipefail

DISK="/dev/sdb"
LABEL="gateway-logs"

# Check if disk exists
if [ ! -b "$DISK" ]; then
    echo "Error: $DISK does not exist"
    exit 1
fi

# Check if already formatted
if blkid "$DISK" | grep -q "$LABEL"; then
    echo "Disk $DISK already has label $LABEL"
    exit 0
fi

echo "WARNING: This will format $DISK and destroy all data on it!"
echo "Disk: $DISK"
lsblk "$DISK"
echo ""
read -p "Type 'yes' to continue: " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted"
    exit 1
fi

# Format the disk
echo "Creating ext4 filesystem with label $LABEL on $DISK..."
mkfs.ext4 -L "$LABEL" "$DISK"

echo "Done! Filesystem created:"
blkid "$DISK"

echo ""
echo "The mount point will be available after next reboot or run:"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl restart var-log-gateway.mount"
