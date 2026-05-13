#!/usr/bin/env bash
# scripts/validate-snmp.sh — SNMP validation for homelab router
set -euo pipefail

ROUTER_LAN_IP="10.10.10.1"
COMMUNITY="public" # Default, or could be read from secret if available locally
TIMEOUT=2

echo "=== SNMP Validation Check ==="

# 1. Check if snmpwalk is available
if ! command -v snmpwalk >/dev/null 2>&1; then
  echo "ERROR: snmpwalk not found. Please install net-snmp packages."
  exit 1
fi

# 2. Basic SNMP Connectivity (SysDescr)
echo -n "Checking SNMP SysDescr from $ROUTER_LAN_IP... "
if sys_descr=$(snmpwalk -v 2c -c "$COMMUNITY" -t "$TIMEOUT" "$ROUTER_LAN_IP" .1.3.6.1.2.1.1.1 2>/dev/null); then
  echo "OK"
  echo "  Description: $(echo "$sys_descr" | cut -d':' -f2-)"
else
  echo "FAILED"
  exit 1
fi

# 3. Interface List Check
echo -n "Checking SNMP Interface list... "
if if_count=$(snmpwalk -v 2c -c "$COMMUNITY" -t "$TIMEOUT" "$ROUTER_LAN_IP" .1.3.6.1.2.1.2.1 2>/dev/null); then
  echo "OK"
  echo "  Interfaces found: $(echo "$if_count" | cut -d':' -f2-)"
else
  echo "FAILED"
  exit 1
fi

echo "=== SNMP Validation Complete ==="
exit 0
