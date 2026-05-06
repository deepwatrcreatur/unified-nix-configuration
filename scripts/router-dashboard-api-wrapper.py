#!/usr/bin/env python3
import importlib.util
import json
import os
import subprocess
import sys
import csv
from datetime import datetime, timezone


def log_warning(message):
    print(message, file=sys.stderr, flush=True)


def get_required_env(name):
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"Missing required environment variable: {name}")
    return value


def load_optional_secret(path, env_name):
    if not path:
        return

    if not os.path.exists(path):
        log_warning(f"Optional secret file not found for {env_name}: {path}")
        return

    try:
        with open(path, "r", encoding="utf-8") as handle:
            os.environ[env_name] = handle.read().strip()
    except OSError as exc:
        log_warning(f"Failed reading optional secret file for {env_name}: {exc}")


def parse_interfaces_env():
    raw = os.environ.get("DASHBOARD_INTERFACES", "[]")
    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as exc:
        log_warning(f"Invalid DASHBOARD_INTERFACES JSON: {exc}")
        return []

    if not isinstance(parsed, list):
        log_warning("DASHBOARD_INTERFACES must decode to a list; ignoring malformed value")
        return []

    return parsed


def read_int_file(handler, path, context):
    raw = handler.read_file(path)
    if raw is None:
        return 0

    text = str(raw).strip()
    if not text:
        return 0

    try:
        return int(text)
    except ValueError:
        log_warning(f"Invalid integer in {path} for {context}: {text!r}")
        return 0


def read_interface_state(handler, path, interface_name):
    raw = handler.read_file(path)
    if raw is None:
        return "UNKNOWN"

    state = str(raw).strip().upper()
    if not state:
        log_warning(f"Missing operstate value for interface {interface_name}")
        return "UNKNOWN"

    return state


UPSTREAM_SERVER = get_required_env("DASHBOARD_UPSTREAM_SERVER")
FAIL2BAN_STATUS_FILE = os.environ.get("DASHBOARD_FAIL2BAN_STATUS_FILE", "")
CLOUDFLARE_TOKEN_FILE = os.environ.get("DASHBOARD_CLOUDFLARE_TOKEN_FILE", "")
DHCP_PROVIDER = os.environ.get("DASHBOARD_DHCP_PROVIDER", "technitium").strip().lower()
KEA_LEASE_FILE = os.environ.get("DASHBOARD_KEA_LEASE_FILE", "").strip()

if not os.path.exists(UPSTREAM_SERVER):
    raise SystemExit(f"DASHBOARD_UPSTREAM_SERVER does not exist: {UPSTREAM_SERVER}")

load_optional_secret(CLOUDFLARE_TOKEN_FILE, "CLOUDFLARE_API_TOKEN")
spec = importlib.util.spec_from_file_location("router_dashboard_upstream", UPSTREAM_SERVER)
if spec is None or spec.loader is None:
    raise SystemExit(f"Unable to load dashboard upstream module from {UPSTREAM_SERVER}")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

dashboard_interfaces = parse_interfaces_env()

interface_role_map = {}
for interface in dashboard_interfaces:
    if not isinstance(interface, dict):
        log_warning(f"Ignoring malformed dashboard interface entry: {interface!r}")
        continue
    device = interface.get("device")
    role = interface.get("role") or device
    if device:
        interface_role_map[device] = role

try:
    KEA_DHCP_META = json.loads(os.environ.get("DASHBOARD_KEA_DHCP", "{}"))
except json.JSONDecodeError as exc:
    log_warning(f"Invalid DASHBOARD_KEA_DHCP JSON: {exc}")
    KEA_DHCP_META = {}

original_handle_fail2ban_status = module.RouterAPIHandler.handle_fail2ban_status
original_handle_dhcp_leases = module.RouterAPIHandler.handle_dhcp_leases


def handle_interface_stats(self):
    try:
        interfaces = {}
        net_path = module.Path("/sys/class/net")

        for iface_path in net_path.iterdir():
            try:
                name = iface_path.name
                if name.startswith(("lo", "docker", "veth", "br-", "virbr")):
                    continue

                stats_path = iface_path / "statistics"
                if not stats_path.exists():
                    continue

                rx_bytes = read_int_file(self, stats_path / "rx_bytes", f"{name} rx_bytes")
                tx_bytes = read_int_file(self, stats_path / "tx_bytes", f"{name} tx_bytes")
                rx_rate, tx_rate = self.calculate_rates(name, rx_bytes, tx_bytes)
                ipv4 = self.get_ipv4(name)
                ipv6_list = self.get_ipv6(name)
                key = interface_role_map.get(name, name)

                interfaces[key] = {
                    "device": name,
                    "state": read_interface_state(self, iface_path / "operstate", name),
                    "ipv4": ipv4,
                    "ipv6": ipv6_list,
                    "rx_bytes": rx_bytes,
                    "tx_bytes": tx_bytes,
                    "rx_rate": rx_rate,
                    "tx_rate": tx_rate,
                    "rx_packets": read_int_file(self, stats_path / "rx_packets", f"{name} rx_packets"),
                    "tx_packets": read_int_file(self, stats_path / "tx_packets", f"{name} tx_packets"),
                    "rx_errors": read_int_file(self, stats_path / "rx_errors", f"{name} rx_errors"),
                    "tx_errors": read_int_file(self, stats_path / "tx_errors", f"{name} tx_errors"),
                }
            except Exception as exc:
                log_warning(f"Failed to collect interface stats for {iface_path}: {exc}")

        self.send_json(interfaces)
    except Exception as exc:
        self.send_error_json(500, str(exc))


def handle_firewall_stats(self):
    try:
        result = subprocess.run(
            ["nft", "-j", "list", "ruleset"],
            capture_output=True,
            text=True,
            timeout=5,
        )

        if result.returncode != 0:
            print(f"Error running nft: {result.stderr}")
            self.send_json({"error": f"Failed to get nftables stats: {result.stderr}"})
            return

        data = json.loads(result.stdout)
        rules_count = 0
        flowtable_active = False
        offloaded_flows = 0

        # Look for flowtable definitions OR rules that add to a flowtable
        for item in data.get("nftables", []):
            if "rule" in item:
                rules_count += 1
                # Check if rule uses a flowtable
                exprs = item.get("rule", {}).get("expr", [])
                for expr in exprs:
                    if "flow" in expr:
                        flowtable_active = True
            if "flowtable" in item:
                flowtable_active = True

        # Fallback check via raw ruleset if JSON parsing didn't find it
        if not flowtable_active:
            raw_result = subprocess.run(
                ["nft", "list", "ruleset"],
                capture_output=True,
                text=True,
                timeout=5,
            )
            if "flowtable" in raw_result.stdout:
                flowtable_active = True

        # Get flowtable flow count if available
        try:
            ft_result = subprocess.run(
                ["conntrack", "-L", "-o", "extended"],
                capture_output=True,
                text=True,
                timeout=3,
            )
            offloaded_flows = ft_result.stdout.count("[OFFLOAD]")
        except Exception as exc:
            log_warning(f"Error running conntrack: {exc}")

        # Get packet counters from ALL configured interfaces
        packets_in = 0
        packets_out = 0
        try:
            for device in interface_role_map.keys():
                rx_path = f"/sys/class/net/{device}/statistics/rx_packets"
                tx_path = f"/sys/class/net/{device}/statistics/tx_packets"
                if os.path.exists(rx_path):
                    rx = self.read_file(rx_path)
                    if rx:
                        packets_in += int(rx)
                if os.path.exists(tx_path):
                    tx = self.read_file(tx_path)
                    if tx:
                        packets_out += int(tx)
        except Exception as exc:
            log_warning(f"Error getting packet counters: {exc}")

        self.send_json(
            {
                "rules_count": rules_count,
                "flowtable_active": flowtable_active,
                "offloaded_flows": offloaded_flows,
                "packets_in": packets_in,
                "packets_out": packets_out,
            }
        )
    except Exception as e:
        print(f"Exception in handle_firewall_stats: {e}")
        self.send_error_json(500, str(e))


def handle_caddy_status(self):
    """Detailed Caddy diagnostics"""
    try:
        systemctl = self.find_systemctl()
        if not systemctl:
            self.send_json({"available": False, "message": "systemctl not found"})
            return

        properties = self.get_unit_properties(
            systemctl,
            "caddy",
            [
                "Id",
                "ActiveState",
                "SubState",
                "Result",
                "ExecMainStatus",
                "ExecStartPre",
                "EnvironmentFiles",
                "ExecStart",
            ],
        )
        caddy_bin = self.find_executable(
            ["/run/current-system/sw/bin/caddy", "/usr/bin/caddy", "caddy"], ["version"]
        ) or self.extract_exec_path(properties.get("ExecStart", ""))

        env_file = "/run/caddy/caddy.env"
        # Use the token file passed from Nix environment
        token_file = CLOUDFLARE_TOKEN_FILE or "/run/agenix/cloudflare-api-key"

        env_configured = "/run/caddy/caddy.env" in properties.get("EnvironmentFiles", "")
        env_present = env_configured or os.path.exists(env_file)
        token_exists = os.path.exists(token_file)
        token_value = ""
        if token_exists:
            token_value = self.read_file(token_file).strip()
        else:
            print(f"Caddy token file NOT FOUND at: {token_file}")

        live_config = None
        config_valid = False
        config_message = "caddy binary not found"

        if properties.get("ActiveState") == "active":
            config_valid, config_message = self.check_live_caddy_admin_config()
            live_config = self.fetch_live_caddy_admin_config()
        elif caddy_bin:
            try:
                validate_env = dict(os.environ)
                if env_present:
                    validate_env.update(self.read_env_file(env_file))
                elif token_value:
                    validate_env["CLOUDFLARE_API_TOKEN"] = token_value

                config_valid, config_message = self.validate_caddy_config(
                    caddy_bin, validate_env
                )
            except Exception as exc:
                config_message = str(exc)

        logs = self.read_service_logs("caddy", 25)
        recent_logs = self.get_recent_caddy_logs(logs)
        latest_error = self.get_latest_caddy_error(logs)
        message = latest_error or config_message
        dns_status = self.get_caddy_dns_status(live_config, token_value)

        if properties.get("ActiveState") == "active" and not latest_error:
            if config_valid:
                message = "Caddy is running and the current config is healthy"
            elif (
                "permission denied" in config_message.lower()
                and "/var/log/caddy/" in config_message
            ):
                message = "Caddy is running; offline validation is blocked by log-file permissions"

        self.send_json(
            {
                "available": True,
                "unit": properties.get("Id", "caddy.service"),
                "activeState": properties.get("ActiveState", "unknown"),
                "subState": properties.get("SubState", "unknown"),
                "result": properties.get("Result", "unknown"),
                "active": properties.get("ActiveState") == "active",
                "configValid": config_valid,
                "configMessage": config_message,
                "environmentFile": {
                    "path": env_file,
                    "configured": env_configured,
                    "present": env_present,
                },
                "cloudflareToken": {
                    "path": token_file,
                    "exists": token_exists,
                    "usableForValidation": bool(token_value),
                },
                "dnsStatus": dns_status,
                "message": message,
                "logs": recent_logs[-12:],
            }
        )
    except Exception as exc:
        print(f"Exception in handle_caddy_status: {exc}")
        self.send_error_json(500, str(exc))


def handle_fail2ban_status(self):
    if FAIL2BAN_STATUS_FILE:
        try:
            if os.path.exists(FAIL2BAN_STATUS_FILE):
                with open(FAIL2BAN_STATUS_FILE, "r", encoding="utf-8") as handle:
                    payload = json.load(handle)
                self.send_json(payload)
                return
            else:
                log_warning(f"Fail2ban snapshot file not found at: {FAIL2BAN_STATUS_FILE}")
        except FileNotFoundError:
            log_warning(f"Fail2ban snapshot file disappeared before read: {FAIL2BAN_STATUS_FILE}")
        except Exception as exc:
            log_warning(f"Error reading fail2ban snapshot: {exc}")

    log_warning("Falling back to original handle_fail2ban_status (sudo)")
    return original_handle_fail2ban_status(self)


def format_kea_expiry(expire_value):
    text = str(expire_value or "").strip()
    if not text:
        return ""

    try:
        return datetime.fromtimestamp(int(text), timezone.utc).isoformat()
    except (ValueError, OSError, OverflowError):
        return text


def load_kea_leases():
    if not KEA_LEASE_FILE:
        raise FileNotFoundError("Kea lease file path is not configured")
    if not os.path.exists(KEA_LEASE_FILE):
        raise FileNotFoundError(f"Kea lease file not found: {KEA_LEASE_FILE}")

    leases_by_address = {}
    with open(KEA_LEASE_FILE, "r", encoding="utf-8", newline="") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            if not row:
                continue

            address = str(row.get("address", "")).strip()
            if not address or address == "address":
                continue

            state = str(row.get("state", "")).strip()
            if state not in {"0", ""}:
                continue

            current_expire = str(row.get("expire", "")).strip()
            lease = {
                "scope": str(KEA_DHCP_META.get("scope", "LAN")),
                "interface": ", ".join(KEA_DHCP_META.get("interfaces", [])) or "kea",
                "address": address,
                "hostname": str(row.get("hostname", "")).strip(),
                "hardwareAddress": str(row.get("hwaddr", "")).strip(),
                "leaseExpires": format_kea_expiry(row.get("expire", "")),
                "type": "dynamic",
                "_expire_raw": current_expire,
            }

            existing = leases_by_address.get(address)
            if existing is None:
                leases_by_address[address] = lease
                continue

            existing_expire = existing.get("_expire_raw", "")
            if current_expire and current_expire >= existing_expire:
                leases_by_address[address] = lease

    leases = []
    for lease in leases_by_address.values():
        lease.pop("_expire_raw", None)
        leases.append(lease)

    leases.sort(key=lambda lease: lease.get("address", ""))
    return leases


def handle_dhcp_leases(self):
    if DHCP_PROVIDER != "kea":
        return original_handle_dhcp_leases(self)

    try:
        all_leases = load_kea_leases()
        scope_name = str(KEA_DHCP_META.get("scope", "LAN"))
        title = str(KEA_DHCP_META.get("title", "Kea DHCP"))
        start_address = str(KEA_DHCP_META.get("startAddress", ""))
        end_address = str(KEA_DHCP_META.get("endAddress", ""))

        scope_stats = [
            {
                "name": scope_name,
                "interface": title,
                "enabled": True,
                "startAddress": start_address,
                "endAddress": end_address,
                "leaseCount": len(all_leases),
            }
        ]

        sections = [
            {
                "id": scope_name,
                "title": title,
                "scope": scope_name,
                "interface": title,
                "enabled": True,
                "startAddress": start_address,
                "endAddress": end_address,
                "leaseCount": len(all_leases),
                "leases": all_leases[:50],
            }
        ]

        self.send_json(
            {
                "available": True,
                "scopes": scope_stats,
                "leases": all_leases[:100],
                "sections": sections,
                "totalLeases": len(all_leases),
                "displayedLeases": min(len(all_leases), 100),
            }
        )
    except Exception as exc:
        self.send_json(
            {
                "available": False,
                "message": f"Kea lease view unavailable: {exc}",
            }
        )


module.RouterAPIHandler.handle_interface_stats = handle_interface_stats
module.RouterAPIHandler.handle_firewall_stats = handle_firewall_stats
module.RouterAPIHandler.handle_caddy_status = handle_caddy_status
module.RouterAPIHandler.handle_fail2ban_status = handle_fail2ban_status
module.RouterAPIHandler.handle_dhcp_leases = handle_dhcp_leases

if __name__ == "__main__":
    module.run_server()
