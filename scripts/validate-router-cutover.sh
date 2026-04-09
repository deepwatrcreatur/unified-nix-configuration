#!/usr/bin/env bash
# scripts/validate-router-cutover.sh — Post-cutover validation for homelab router
set -euo pipefail

ROUTER_IP="10.10.10.1"
DOMAIN="deepwatercreature.com"

# Critical hosts from lib/hosts.nix that depend on reserved leases
declare -A CRITICAL_HOSTS=(
  ["attic-cache"]="10.10.11.39"
  ["authentik-host"]="10.10.11.70"
  ["inference1"]="10.10.11.131"
  ["homeserver"]="10.10.11.69"
  ["ap-ruqayya"]="10.10.11.20"
  ["ap-nosheen-living"]="10.10.11.21"
  ["ap-nosheen-bedroom"]="10.10.11.22"
)

echo "=== Router Post-Cutover Validation ==="

# 1. Connectivity to Router
echo -n "Checking router reachability ($ROUTER_IP)... "
if ping -c 1 -W 2 "$ROUTER_IP" >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAILED"
  exit 1
fi

# 2. WAN Connectivity
echo -n "Checking Internet connectivity (1.1.1.1)... "
if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAILED (Advisory)"
fi

# 3. Technitium Service Status
echo -n "Checking Technitium DNS Server service... "
TECH_STATUS=$(ssh "$ROUTER_IP" "systemctl is-active technitium-dns-server" || echo "unknown")
if [ "$TECH_STATUS" == "active" ]; then
  echo "OK"
else
  echo "FAILED: $TECH_STATUS"
fi

# 4. Technitium DHCP Scope Name
echo -n "Checking DHCP scope 'LAN' presence... "
# We check if LAN.scope exists
if ssh "$ROUTER_IP" "/run/wrappers/bin/sudo ls /var/lib/technitium-dns-server/scopes/LAN.scope" >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAILED (Check if scope is named 'Default' instead)"
fi

# 5. Critical Host Reachability (Reserved IPs)
echo "Checking critical host reachability (reserved IPs):"
for host in "${!CRITICAL_HOSTS[@]}"; do
  expected_ip="${CRITICAL_HOSTS[$host]}"
  echo -n "  - $host ($expected_ip)... "
  if ping -c 1 -W 1 "$expected_ip" >/dev/null 2>&1; then
    echo "OK"
  else
    # Try to find current IP if wrong
    actual_ip=$(ssh "$ROUTER_IP" "/run/wrappers/bin/sudo grep -i \"leased IP address .* to .*$host\" /var/lib/technitium-dns-server/logs/\$(date +%Y-%m-%d).log | tail -n 1 | grep -oE 'leased IP address \[[0-9.]+' | grep -oE '[0-9.]+' | head -n 1" || echo "unknown")
    if [ -n "$actual_ip" ] && [ "$actual_ip" != "unknown" ]; then
      echo "FAILED (Actually at $actual_ip)"
    else
      echo "FAILED (Unreachable)"
    fi
  fi
done

# 6. Dashboard Reachability (Management Plane)
MGMT_IP="192.168.100.100"
echo -n "Checking Dashboard on Management Plane ($MGMT_IP:8888)... "
if curl -s -m 2 "http://$MGMT_IP:8888" >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAILED (Advisory)"
fi

echo "=== Validation Complete ==="
