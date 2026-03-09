#!/usr/bin/env bash
# Import DHCP reservations from JSON file into Technitium DNS Server
# Usage: ./import-dhcp-reservations.sh <json-file> <scope-name> [technitium-url] [token]

set -uo pipefail

JSON_FILE="${1:-}"
SCOPE_NAME="${2:-}"
TECHNITIUM_URL="${3:-http://localhost:5380}"
TOKEN="${4:-}"

if [[ -z "$JSON_FILE" || -z "$SCOPE_NAME" ]]; then
    echo "Usage: $0 <json-file> <scope-name> [technitium-url] [token]"
    echo ""
    echo "Arguments:"
    echo "  json-file      Path to dhcp-reservations.json"
    echo "  scope-name     Name of DHCP scope (e.g., 'LAN')"
    echo "  technitium-url Optional: Technitium server URL (default: http://localhost:5380)"
    echo "  token          Optional: API token (will prompt if not provided)"
    echo ""
    echo "Example:"
    echo "  $0 ~/dhcp-reservations.json LAN"
    exit 1
fi

if [[ ! -f "$JSON_FILE" ]]; then
    echo "Error: JSON file not found: $JSON_FILE"
    exit 1
fi

# Prompt for token if not provided
if [[ -z "$TOKEN" ]]; then
    read -sp "Enter Technitium API token (from Settings > API): " TOKEN </dev/tty
    echo
fi

if [[ -z "$TOKEN" ]]; then
    echo "Error: Token is required"
    exit 1
fi

# Extract reservations from JSON
TOTAL_COUNT=$(jq -r '.totalCount' "$JSON_FILE")

echo "Found $TOTAL_COUNT DHCP reservations to import"
echo "Target scope: $SCOPE_NAME"
echo "Technitium URL: $TECHNITIUM_URL"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

# Store all reservations in array to avoid stdin issues
mapfile -t RESERVATIONS < <(jq -c '.dhcpReservations[]' "$JSON_FILE")

# Process each reservation
for reservation in "${RESERVATIONS[@]}"; do
    MAC=$(printf "%s" "$reservation" | jq -r '.macAddress')
    IP=$(printf "%s" "$reservation" | jq -r '.ipAddress')
    HOSTNAME=$(printf "%s" "$reservation" | jq -r '.hostName // ""')
    DESCRIPTION=$(printf "%s" "$reservation" | jq -r '.description // ""')
    
    # Combine hostname and description for comments
    COMMENTS=""
    if [[ -n "$HOSTNAME" && -n "$DESCRIPTION" ]]; then
        COMMENTS="$HOSTNAME - $DESCRIPTION"
    elif [[ -n "$HOSTNAME" ]]; then
        COMMENTS="$HOSTNAME"
    elif [[ -n "$DESCRIPTION" ]]; then
        COMMENTS="$DESCRIPTION"
    fi
    
    echo -n "Adding $MAC -> $IP"
    if [[ -n "$COMMENTS" ]]; then
        echo -n " ($COMMENTS)"
    fi
    echo -n "... "
    
    # API call to add DHCP reservation
    # Technitium API endpoint: /api/dhcp/scopes/addReservedLease
    RESPONSE=$(curl -s -X POST "$TECHNITIUM_URL/api/dhcp/scopes/addReservedLease" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "token=$TOKEN" \
        --data-urlencode "name=$SCOPE_NAME" \
        --data-urlencode "hardwareAddress=$MAC" \
        --data-urlencode "ipAddress=$IP" \
        --data-urlencode "hostName=$HOSTNAME" \
        --data-urlencode "comments=$COMMENTS" 2>&1 || echo '{"status":"error"}')
    
    STATUS=$(printf "%s" "$RESPONSE" | jq -r '.status // "error"')
    
    if [[ "$STATUS" == "ok" ]]; then
        echo "✓ Success"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        ERROR_MSG=$(printf "%s" "$RESPONSE" | jq -r '.errorMessage // "Unknown error"')
        # Check if it's a duplicate error
        if [[ "$ERROR_MSG" == *"already exists"* ]] || [[ "$ERROR_MSG" == *"already reserved"* ]] || [[ "$ERROR_MSG" == *"Failed to add reserved lease"* ]]; then
            echo "⊙ Already exists (skipping)"
        else
            echo "✗ Failed: $ERROR_MSG"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
    
    # Rate limiting - small delay to avoid overwhelming the server
    sleep 0.1
done

echo ""
echo "Import complete!"
echo "Success: $SUCCESS_COUNT"
echo "Failed: $FAIL_COUNT"
