#!/usr/bin/env bash
# scripts/validate-router-cutover.sh — Post-cutover validation for homelab router
set -euo pipefail

# Default to management plane for diagnostics
ROUTER_SSH_TARGET="192.168.100.100"
ROUTER_LAN_IP="10.10.10.1"
DOMAIN="deepwatercreature.com"
SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new"
BLOCKING_FAILED=0

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

# 1. Connectivity to Router Management Plane
echo -n "Checking router management reachability ($ROUTER_SSH_TARGET)... "
if ping -c 1 -W 2 "$ROUTER_SSH_TARGET" >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAILED"
  exit 1
fi

# 2. Connectivity to Router LAN IP
echo -n "Checking router LAN reachability ($ROUTER_LAN_IP)... "
if ping -c 1 -W 2 "$ROUTER_LAN_IP" >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAILED (Advisory - Check data-plane cable)"
fi

# 3. WAN Connectivity
echo -n "Checking Internet connectivity (1.1.1.1)... "
if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAILED (Advisory)"
fi

# 4. Kea DHCP Service Status
echo -n "Checking Kea DHCP4 Server service... "
# shellcheck disable=SC2086
KEA_STATUS=$(ssh $SSH_OPTS "$ROUTER_SSH_TARGET" "systemctl is-active kea-dhcp4-server" 2>/dev/null || echo "unknown")
if [ "$KEA_STATUS" = "active" ]; then
  echo "OK"
else
  echo "FAILED: $KEA_STATUS"
  BLOCKING_FAILED=1
fi

# 5. Kea DDNS Service Status
echo -n "Checking Kea DHCP-DDNS Server service... "
# shellcheck disable=SC2086
D2_STATUS=$(ssh $SSH_OPTS "$ROUTER_SSH_TARGET" "systemctl is-active kea-dhcp-ddns-server" 2>/dev/null || echo "unknown")
if [ "$D2_STATUS" = "active" ]; then
  echo "OK"
else
  echo "FAILED: $D2_STATUS"
  BLOCKING_FAILED=1
fi

# 6. Critical Host Reachability (Reserved IPs)
echo "Checking critical host reachability (reserved IPs):"
for host in "${!CRITICAL_HOSTS[@]}"; do
  expected_ip="${CRITICAL_HOSTS[$host]}"
  echo -n "  - $host ($expected_ip)... "
  if ping -c 1 -W 1 "$expected_ip" >/dev/null 2>&1; then
    echo "OK"
  else
    # Try to find current lease in Kea
    # shellcheck disable=SC2086
    actual_ip=$(ssh $SSH_OPTS "$ROUTER_SSH_TARGET" "/run/wrappers/bin/sudo grep -i \"$host\" /var/lib/kea/dhcp4.leases | tail -n 1 | cut -d',' -f1" 2>/dev/null || echo "unknown")
    if [ -n "$actual_ip" ] && [ "$actual_ip" != "unknown" ]; then
      echo "FAILED (Advisory: Actually at $actual_ip)"
    else
      echo "FAILED (Advisory: Unreachable)"
    fi
  fi
done

# 7. Dashboard Reachability (Management Plane)
echo -n "Checking Dashboard on Management Plane ($ROUTER_SSH_TARGET:8888)... "
if curl -s -m 2 "http://$ROUTER_SSH_TARGET:8888" >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAILED (Advisory)"
fi

echo "=== Validation Complete ==="
if [ "$BLOCKING_FAILED" -ne 0 ]; then
  echo "FAILURE: One or more blocking validation checks failed."
  exit 1
fi
exit 0
