#!/usr/bin/env bash
# scripts/validate-router-cutover.sh — Post-cutover validation for homelab router
#
# This script performs high-level health checks after a router cutover.
# Checks are categorized as BLOCKING (must pass for a stable network) 
# or ADVISORY (useful but non-critical).

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ROUTER_IP="10.10.10.1"
DOMAIN="deepwatercreature.com"
MGMT_IP="192.168.100.100"

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

function check_result() {
  local status=$1
  local message=$2
  local type=${3:-BLOCKING} # BLOCKING or ADVISORY

  if [ "$status" -eq 0 ]; then
    printf "${GREEN}[PASS]${NC} %s\n" "$message"
  else
    if [ "$type" == "BLOCKING" ]; then
      printf "${RED}[FAIL]${NC} %s (CRITICAL)\n" "$message"
      GLOBAL_FAIL=1
    else
      printf "${YELLOW}[WARN]${NC} %s (ADVISORY)\n" "$message"
    fi
  fi
}

GLOBAL_FAIL=0

echo "=== Router Post-Cutover Validation ==="

# 1. Connectivity to Router
ping -c 1 -W 2 "$ROUTER_IP" >/dev/null 2>&1
check_result $? "Router reachability ($ROUTER_IP)"

# 2. WAN Connectivity
ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1
check_result $? "Internet connectivity (1.1.1.1)" "ADVISORY"

# 3. Technitium Service Status
TECH_STATUS=$(ssh "$ROUTER_IP" "systemctl is-active technitium-dns-server" 2>/dev/null || echo "unknown")
[ "$TECH_STATUS" == "active" ]
check_result $? "Technitium DNS Server service status"

# 4. Technitium DHCP Scope Name
ssh "$ROUTER_IP" "/run/wrappers/bin/sudo ls /var/lib/technitium-dns-server/scopes/LAN.scope" >/dev/null 2>&1
check_result $? "DHCP scope 'LAN' presence"

# 5. Critical Host Reachability (Reserved IPs)
echo "Checking critical host reachability (reserved IPs):"
for host in "${!CRITICAL_HOSTS[@]}"; do
  expected_ip="${CRITICAL_HOSTS[$host]}"
  if ping -c 1 -W 1 "$expected_ip" >/dev/null 2>&1; then
    check_result 0 "Host $host is at expected IP $expected_ip"
  else
    # Try to find current IP if wrong
    actual_ip=$(ssh "$ROUTER_IP" "/run/wrappers/bin/sudo grep -i \"leased IP address .* to .*$host\" /var/lib/technitium-dns-server/logs/\$(date +%Y-%m-%d).log 2>/dev/null | tail -n 1 | grep -oE 'leased IP address \[[0-9.]+' | grep -oE '[0-9.]+' | head -n 1" || echo "")
    if [ -n "$actual_ip" ]; then
      check_result 1 "Host $host is at WRONG IP $actual_ip (Expected $expected_ip)"
    else
      check_result 1 "Host $host ($expected_ip) is UNREACHABLE"
    fi
  fi
done

# 6. Dashboard Reachability (Management Plane)
curl -s -m 2 "http://$MGMT_IP:8888" >/dev/null 2>&1
check_result $? "Dashboard reachable on Management Plane ($MGMT_IP:8888)" "ADVISORY"

echo "----------------------------------------"
if [ "$GLOBAL_FAIL" -eq 0 ]; then
  echo -e "${GREEN}SUCCESS: Router cutover validation passed.${NC}"
else
  echo -e "${RED}FAILURE: One or more blocking checks failed.${NC}"
  echo "Action: Reboot critical devices or force DHCP renewal to pick up reserved IPs."
fi
echo "=== Validation Complete ==="
