#!/usr/bin/env bash
# scripts/validate-snmp.sh — SNMP validation for homelab router
set -euo pipefail

ROUTER_LAN_IP="10.10.10.1"
COMMUNITY="${SNMP_COMMUNITY:-}"
TIMEOUT=2

if [ -z "$COMMUNITY" ]; then
  echo "Set SNMP_COMMUNITY to the router's SNMPv2c community string." >&2
  exit 2
fi

echo "=== SNMP Validation Check ==="

if ! command -v snmpwalk >/dev/null 2>&1; then
  echo "ERROR: snmpwalk not found. Please install net-snmp packages."
  exit 1
fi

echo -n "Checking SNMP SysDescr from $ROUTER_LAN_IP... "
if sys_descr=$(snmpwalk -v 2c -c "$COMMUNITY" -t "$TIMEOUT" "$ROUTER_LAN_IP" .1.3.6.1.2.1.1.1 2>/dev/null); then
  echo "OK"
  echo "  Description: $(echo "$sys_descr" | cut -d':' -f2-)"
else
  echo "FAILED"
  exit 1
fi

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
