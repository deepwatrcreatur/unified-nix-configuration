# Gateway Scripts

Scripts for managing the gateway router (10.10.11.97).

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
# Run on gateway host
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
