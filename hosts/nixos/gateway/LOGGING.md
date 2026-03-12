# Gateway Logging Configuration

## Overview

The gateway uses a dedicated 10GB spinning disk (HDD) for all logging to preserve SSD lifespan. The HDD is mounted at `/var/log/gateway` with subdirectories for different services.

## Disk Layout

```
/var/log/gateway (HDD - 10GB)
├── journal/              -> systemd journal (bind mounted to /var/log/journal)
├── technitium/           -> Technitium DNS logs
├── system/               -> System logs
├── netdata/              -> Netdata monitoring logs
├── grafana/              -> Grafana dashboard logs  
├── prometheus/           -> Prometheus metrics logs
└── nginx-proxy-manager/  -> NPM reverse proxy logs
```

## Configuration Files

- **default.nix**: Main mount point and setup service
- **logging-config.nix**: Service-specific log directory configurations
- **router-dashboard.nix**: Monitoring services (Netdata, Grafana, Prometheus)

## Mount Configuration

The HDD uses UUID-based mounting to handle device reassignment:
```nix
fileSystems."/var/log/gateway" = {
  device = "/dev/disk/by-uuid/f4b71c97-3f7f-47b3-a644-d82e051d5343";
  options = [ "noatime" "nofail" "x-systemd.automount" ];
  neededForBoot = false;
};
```

**Options explained:**
- `noatime`: Don't update access times (reduces writes)
- `nofail`: Boot succeeds even if mount fails
- `x-systemd.automount`: Mount on-demand when accessed
- `neededForBoot = false`: Not required during early boot

## Journal Configuration

Systemd journal is bind-mounted to the HDD:
```nix
fileSystems."/var/log/journal" = {
  device = "/var/log/gateway/journal";
  fsType = "none";
  options = [ "bind" "nofail" "x-systemd.automount" ];
};
```

Journal settings:
- `Storage=persistent`: Keep logs across reboots
- `SystemMaxUse=2G`: Maximum 2GB for system logs
- `RuntimeMaxUse=100M`: Maximum 100MB in RAM

## Service Configurations

### Technitium DNS
```nix
systemd.services.technitium-dns-server.environment = {
  TECHNITIUM_DNS_LOG_FOLDER = "/var/log/gateway/technitium";
};
```

### Grafana
```nix
services.grafana.settings.paths.logs = "/var/log/gateway/grafana";
```

### Netdata
```nix
systemd.services.netdata.environment = {
  NETDATA_LOG_DIR = "/var/log/gateway/netdata";
};
```

## Checking Log Status

### View HDD mount status
```bash
mount | grep gateway
df -h /var/log/gateway
```

### Check journal location
```bash
journalctl --disk-usage
ls -la /var/log/journal
```

### View service logs
```bash
# Technitium logs
ls -la /var/log/gateway/technitium/

# System journal
journalctl -xe

# Grafana logs
tail -f /var/log/gateway/grafana/grafana.log

# Netdata logs  
tail -f /var/log/gateway/netdata/error.log
```

## Disk Space Management

### Check disk usage
```bash
# Overall HDD usage
df -h /var/log/gateway

# Per-directory usage
du -sh /var/log/gateway/*

# Journal size
journalctl --disk-usage
```

### Clean old logs
```bash
# Clean journal (keep last 7 days)
sudo journalctl --vacuum-time=7d

# Clean journal (keep max 1GB)
sudo journalctl --vacuum-size=1G

# Rotate service logs (if configured)
sudo logrotate -f /etc/logrotate.conf
```

## SSD Protection

By redirecting logs to HDD, we protect the SSD from:
- **Write amplification**: Constant log writes
- **Wear leveling**: Reduced write cycles
- **Increased lifespan**: SSD lasts longer

## Boot Behavior

If the HDD fails or is missing:
1. System boots normally (thanks to `nofail`)
2. Logs fall back to `/var/log` on SSD temporarily
3. No emergency mode or boot failure
4. Once HDD is available, automount engages

## Troubleshooting

### HDD not mounting
```bash
# Check if disk exists
lsblk

# Check UUID
sudo blkid /dev/sdb

# Manually mount
sudo mount /var/log/gateway

# Check systemd mount unit
systemctl status var-log-gateway.mount
```

### Services not logging to HDD
```bash
# Check if directories exist
ls -la /var/log/gateway/

# Check permissions
sudo ls -la /var/log/gateway/technitium/

# Restart service
sudo systemctl restart technitium-dns-server

# Check environment variables
systemctl show technitium-dns-server | grep LOG
```

### Journal not on HDD
```bash
# Check bind mount
mount | grep journal

# Check journal location
ls -la /var/log/journal

# Force journal flush
sudo systemctl kill --signal=SIGUSR1 systemd-journald
```

## Migration from SSD

If you have existing logs on SSD and want to migrate:

```bash
# Stop services
sudo systemctl stop technitium-dns-server netdata grafana

# Create directories on HDD
sudo mkdir -p /var/log/gateway/{technitium,netdata,grafana,system}

# Copy existing logs
sudo rsync -av /var/log/technitium/ /var/log/gateway/technitium/
# (repeat for other services)

# Start services (they'll now use HDD)
sudo systemctl start technitium-dns-server netdata grafana

# Clean old logs from SSD after verification
sudo rm -rf /var/log/technitium
```

## Performance

HDD is suitable for logs because:
- Sequential writes (HDD strength)
- Not latency-sensitive
- High capacity (10GB vs limited SSD)
- Cheaper per GB for archival

SSD is preserved for:
- OS and binaries
- Fast random access
- Service databases
- Configuration files
