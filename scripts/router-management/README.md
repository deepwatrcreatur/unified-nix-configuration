# Router Management Scripts

Scripts for managing the NixOS router and its Technitium/Caddy edge services.

## Technitium Clustering

The current recommended spare-router model is:

- `router` is the primary Technitium node
- `router-backup` is a management-reachable standby node
- Technitium clustering is used for DNS/admin configuration sync only

Important limitation:

- released Technitium clustering does not currently replicate DHCP scopes or
  lease state

So after enabling clustering, still verify on `router-backup`:

- the `LAN` DHCP scope exists
- the dynamic pool is set correctly in the web UI
- reservations imported from git are present as expected

## export-dhcp-reservations.sh

Exports DHCP reservations from Technitium DNS Server to JSON file for backup.

### Usage

```bash
# Run on router host
./export-dhcp-reservations.sh LAN dhcp-backup.json
# Will prompt for API token

# Or provide token directly
./export-dhcp-reservations.sh LAN dhcp-backup.json http://localhost:5380 "your-token-here"
```

### What it does

- Fetches all reserved leases from the specified DHCP scope via API
- Exports to JSON format compatible with import-dhcp-reservations.sh
- Shows sample entries and total count

### Backup workflow

1. Export reservations periodically:
   ```bash
   ./export-dhcp-reservations.sh LAN backup-$(date +%Y%m%d).json
   ```
2. Store backup files in cloud storage (rclone, git, etc.)
3. To restore, use `import-dhcp-reservations.sh` with the exported JSON

---

## import-dhcp-reservations.sh

Imports DHCP reservations from JSON file into Technitium DNS Server via API.

### Prerequisites

1. **Create DHCP Scope first** in Technitium web UI (http://10.10.11.97:5380/)
   - Go to DHCP section
   - Create scope (e.g., name: "LAN", range: 10.10.10.0/16)

2. **Get API Token**:
   - Web UI → Settings → API
   - Generate/copy token

### Usage

```bash
# Run on router host
./import-dhcp-reservations.sh ~/dhcp-reservations.json LAN
# Will prompt for API token

# Or provide token directly
./import-dhcp-reservations.sh ~/dhcp-reservations.json LAN http://localhost:5380 "your-token-here"
```

### What it does

- Reads DHCP reservations from JSON (extracted from OPNsense config)
- Uses Technitium API to add each reservation to the specified scope
- Reports success/failure for each entry
- Adds hostname and description as comments in Technitium

### After import

Use Technitium's **Backup Settings** feature in web UI to save configuration to zip file for safekeeping.
