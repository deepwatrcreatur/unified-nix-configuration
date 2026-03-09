#!/usr/bin/env bash
# Export DHCP reservations from Technitium DNS Server to JSON file
# Usage: ./export-dhcp-reservations.sh <scope-name> <output-file> [technitium-url] [token]

set -uo pipefail

SCOPE_NAME="${1:-}"
OUTPUT_FILE="${2:-}"
TECHNITIUM_URL="${3:-http://localhost:5380}"
TOKEN="${4:-}"

if [[ -z "$SCOPE_NAME" || -z "$OUTPUT_FILE" ]]; then
    echo "Usage: $0 <scope-name> <output-file> [technitium-url] [token]"
    echo ""
    echo "Arguments:"
    echo "  scope-name     Name of DHCP scope (e.g., 'LAN')"
    echo "  output-file    Path to save JSON output"
    echo "  technitium-url Optional: Technitium server URL (default: http://localhost:5380)"
    echo "  token          Optional: API token (will prompt if not provided)"
    echo ""
    echo "Example:"
    echo "  $0 LAN dhcp-reservations-backup.json"
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

echo "Fetching DHCP scope: $SCOPE_NAME"
echo "Technitium URL: $TECHNITIUM_URL"
echo ""

# Fetch scope details including reserved leases
RESPONSE=$(curl -s -X GET "$TECHNITIUM_URL/api/dhcp/scopes/get?token=$TOKEN&name=$SCOPE_NAME")

STATUS=$(echo "$RESPONSE" | jq -r '.status // "error"')

if [[ "$STATUS" != "ok" ]]; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.errorMessage // "Unknown error"')
    echo "Error: Failed to fetch scope - $ERROR_MSG"
    exit 1
fi

# Extract reserved leases from the response
RESERVED_LEASES=$(echo "$RESPONSE" | jq -r '.response.reservedLeases // []')

# Check if any reservations exist
LEASE_COUNT=$(echo "$RESERVED_LEASES" | jq 'length')

if [[ "$LEASE_COUNT" -eq 0 ]]; then
    echo "No reserved leases found in scope: $SCOPE_NAME"
    exit 0
fi

echo "Found $LEASE_COUNT reserved leases"

# Transform to our JSON format
OUTPUT=$(jq -n \
    --argjson leases "$RESERVED_LEASES" \
    --arg scope "$SCOPE_NAME" \
    '{
        dhcpReservations: [
            $leases[] | {
                macAddress: .hardwareAddress,
                ipAddress: .address,
                hostName: (.hostName // ""),
                description: (.comments // "")
            }
        ],
        source: ("Technitium DNS Server - Scope: " + $scope),
        extractedDate: (now | strftime("%Y-%m-%d %H:%M:%S UTC")),
        totalCount: ($leases | length)
    }')

# Save to file
echo "$OUTPUT" > "$OUTPUT_FILE"

echo ""
echo "Export complete!"
echo "Saved $LEASE_COUNT reservations to: $OUTPUT_FILE"
echo ""
echo "Sample entries:"
echo "$OUTPUT" | jq '.dhcpReservations[0:3]'
