#!/usr/bin/env bash
set -euo pipefail

# Sync DNS records to Technitium DNS Server
# Usage: ./sync-dns-records.sh [mappings_file] [api_key] [server_url] [zone]
# If api_key is not provided, reads from sops secret at ~/.config/sops/secrets/technitium-api-key

MAPPINGS_FILE="${1:-dns-mappings.txt}"
API_KEY="${2:-}"
SERVER_URL="${3:-http://10.10.10.1:5380}"
ZONE="${4:-deepwatercreature.com}"

# If no API key provided, try to read from sops
if [[ -z "$API_KEY" ]]; then
    SOPS_SECRET_PATH="$HOME/.config/sops/secrets/technitium-api-key"
    if [[ -f "$SOPS_SECRET_PATH" ]]; then
        API_KEY=$(cat "$SOPS_SECRET_PATH")
    else
        echo "Error: No API key provided and sops secret not found at $SOPS_SECRET_PATH"
        echo "Usage: $0 [mappings_file] <api_key> [server_url] [zone]"
        exit 1
    fi
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check if mappings file exists
if [[ ! -f "$MAPPINGS_FILE" ]]; then
    log_error "Mappings file not found: $MAPPINGS_FILE"
    exit 1
fi

# Ensure zone exists (create if not)
log_info "Checking if zone $ZONE exists..."
ZONE_CHECK=$(curl -s "$SERVER_URL/api/zones/list?token=$API_KEY" | jq -r ".response.zones[] | select(.name==\"$ZONE\") | .name")

if [[ -z "$ZONE_CHECK" ]]; then
    log_warn "Zone $ZONE does not exist, creating..."
    curl -s -X POST "$SERVER_URL/api/zones/create?token=$API_KEY&domain=$ZONE&type=Primary" > /dev/null
    log_info "Zone $ZONE created"
else
    log_info "Zone $ZONE exists"
fi

# Process mappings file
log_info "Processing DNS records from $MAPPINGS_FILE..."
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    
    # Parse line: hostname ip [record_type]
    read -r hostname ip record_type <<< "$line"
    record_type="${record_type:-A}"
    
    # Skip if hostname or IP is empty
    [[ -z "$hostname" ]] || [[ -z "$ip" ]] && continue
    
    # Check if record already exists with correct IP
    EXISTING=$(curl -s "$SERVER_URL/api/zones/records/get?token=$API_KEY&domain=$hostname.$ZONE&zone=$ZONE&type=$record_type" | jq -r '.response.records[0].rData.ipAddress // empty')
    
    if [[ "$EXISTING" == "$ip" ]]; then
        log_info "⊙ Record already exists: $hostname.$ZONE -> $ip (skipping)"
        continue
    fi
    
    log_info "Adding/Updating $record_type record: $hostname.$ZONE -> $ip"
    
    # Delete existing record if present (to update)
    if [[ -n "$EXISTING" ]]; then
        curl -s -X POST "$SERVER_URL/api/zones/records/delete?token=$API_KEY&domain=$hostname.$ZONE&type=$record_type" > /dev/null 2>&1 || true
    fi
    
    # Add new record
    RESPONSE=$(curl -s -X POST "$SERVER_URL/api/zones/records/add" \
        -d "token=$API_KEY" \
        -d "domain=$hostname.$ZONE" \
        -d "zone=$ZONE" \
        -d "type=$record_type" \
        -d "ipAddress=$ip" \
        -d "ttl=3600")
    
    if echo "$RESPONSE" | jq -e '.status == "ok"' > /dev/null 2>&1; then
        log_info "✓ Successfully added $hostname.$ZONE"
    else
        log_error "✗ Failed to add $hostname.$ZONE"
        echo "$RESPONSE" | jq '.'
    fi
done < "$MAPPINGS_FILE"

log_info "DNS sync complete!"
