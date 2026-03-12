#!/bin/bash
# Fault-tolerant logging setup for any Linux host with spinning disk
# Configures systemd journal to use HDD with automatic SSD fallback
#
# Usage: ./setup-hdd-logging.sh <mount-point> <device-uuid> [max-journal-size]
#
# Example: ./setup-hdd-logging.sh /mnt/logs 947be3a2-edf8-49f0-85c9-329ae56a9bf1 10G

set -e

# Configuration
MOUNT_POINT="${1:-/mnt/logs}"
DEVICE_UUID="${2}"
MAX_JOURNAL_SIZE="${3:-10G}"

if [ -z "$DEVICE_UUID" ]; then
    echo "Error: Device UUID required"
    echo "Usage: $0 <mount-point> <device-uuid> [max-journal-size]"
    echo ""
    echo "Find UUID with: blkid"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Error: Must run as root"
    exit 1
fi

echo "=== Fault-Tolerant HDD Logging Setup ==="
echo "Mount point: $MOUNT_POINT"
echo "Device UUID: $DEVICE_UUID"
echo "Max journal: $MAX_JOURNAL_SIZE"
echo ""

# 1. Backup fstab
echo "1. Backing up fstab..."
BACKUP_FILE="/etc/fstab.backup-$(date +%Y%m%d-%H%M%S)"
cp /etc/fstab "$BACKUP_FILE"
echo "   Backup: $BACKUP_FILE"

# 2. Update or add fstab entry
echo "2. Configuring fstab with nofail..."
if grep -q "$MOUNT_POINT" /etc/fstab; then
    # Update existing entry
    if grep "$MOUNT_POINT" /etc/fstab | grep -q "nofail"; then
        echo "   nofail already present"
    else
        sed -i "s|UUID=$DEVICE_UUID $MOUNT_POINT ext4 [^0-9]*|UUID=$DEVICE_UUID $MOUNT_POINT ext4 defaults,noatime,nofail,x-systemd.device-timeout=5 |" /etc/fstab
        echo "   Updated existing entry"
    fi
else
    # Add new entry
    echo "UUID=$DEVICE_UUID $MOUNT_POINT ext4 defaults,noatime,nofail,x-systemd.device-timeout=5 0 2" >> /etc/fstab
    echo "   Added new entry"
fi

# 3. Create mount point if needed
if [ ! -d "$MOUNT_POINT" ]; then
    echo "3. Creating mount point..."
    mkdir -p "$MOUNT_POINT"
fi

# 4. Mount if not already mounted
echo "4. Mounting HDD..."
if ! mountpoint -q "$MOUNT_POINT"; then
    mount "$MOUNT_POINT" || echo "   Warning: Could not mount. Will mount on reboot."
else
    echo "   Already mounted"
fi

# 5. Create directory structure
echo "5. Creating log directories..."
mkdir -p "$MOUNT_POINT/journal"
mkdir -p "$MOUNT_POINT/system"
mkdir -p "$MOUNT_POINT/services"
mkdir -p "$MOUNT_POINT/apt"

# 6. Set permissions
echo "6. Setting permissions..."
if getent group systemd-journal > /dev/null 2>&1; then
    chown root:systemd-journal "$MOUNT_POINT/journal"
else
    chown root:root "$MOUNT_POINT/journal"
fi
chmod 755 "$MOUNT_POINT/journal"
chmod 755 "$MOUNT_POINT/system"
chmod 755 "$MOUNT_POINT/services"
chmod 755 "$MOUNT_POINT/apt"

# 7. Configure journald
echo "7. Configuring systemd journal..."
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/hdd-logging.conf << EOF
[Journal]
Storage=persistent
SystemMaxUse=$MAX_JOURNAL_SIZE
SystemMaxFileSize=500M
RuntimeMaxUse=200M
Compress=yes
EOF

# 8. Create journal bind mount unit
echo "8. Creating journal bind mount..."
MOUNT_UNIT_NAME=$(systemd-escape -p --suffix=mount "$MOUNT_POINT")
cat > /etc/systemd/system/var-log-journal.mount << EOF
[Unit]
Description=Journal to HDD
After=${MOUNT_UNIT_NAME}
ConditionPathExists=$MOUNT_POINT/journal

[Mount]
What=$MOUNT_POINT/journal
Where=/var/log/journal
Type=none
Options=bind,nofail

[Install]
WantedBy=multi-user.target
EOF

# 9. Apply changes
echo "9. Applying changes..."
systemctl daemon-reload
systemctl enable var-log-journal.mount
systemctl start var-log-journal.mount 2>/dev/null || echo "   (mount will activate on journal restart)"
systemctl restart systemd-journald

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Configured mounts:"
grep "$MOUNT_POINT" /etc/fstab
echo ""
echo "Directory structure:"
ls -lah "$MOUNT_POINT/" | grep -v "lost+found"
echo ""
echo "Journal status:"
journalctl --disk-usage
echo ""
echo "Mount status:"
mount | grep "$MOUNT_POINT" || echo "Not mounted (will mount on next boot)"
echo ""
echo "✅ Fault-tolerance features:"
echo "  ✓ nofail: boots even if HDD fails/missing"
echo "  ✓ x-systemd.device-timeout=5: only wait 5s for HDD"
echo "  ✓ bind mount: journal on HDD when available"
echo "  ✓ ConditionPathExists: safe mount conditions"
echo "  ✓ Falls back to /var/log on primary disk if HDD unavailable"
echo ""
echo "Backup saved to: $BACKUP_FILE"
echo ""
echo "To verify after reboot:"
echo "  journalctl --disk-usage"
echo "  df -h $MOUNT_POINT"
echo "  mount | grep journal"
