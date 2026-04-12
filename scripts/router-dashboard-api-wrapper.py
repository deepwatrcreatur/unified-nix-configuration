#!/usr/bin/env python3
import importlib.util
import json
import os

UPSTREAM_SERVER = os.environ["DASHBOARD_UPSTREAM_SERVER"]
FAIL2BAN_STATUS_FILE = os.environ.get("DASHBOARD_FAIL2BAN_STATUS_FILE", "")
CLOUDFLARE_TOKEN_FILE = os.environ.get("DASHBOARD_CLOUDFLARE_TOKEN_FILE", "")

if CLOUDFLARE_TOKEN_FILE and os.path.exists(CLOUDFLARE_TOKEN_FILE):
    try:
        with open(CLOUDFLARE_TOKEN_FILE, "r", encoding="utf-8") as handle:
            os.environ["CLOUDFLARE_API_TOKEN"] = handle.read().strip()
    except Exception:
        pass

spec = importlib.util.spec_from_file_location("router_dashboard_upstream", UPSTREAM_SERVER)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

try:
    dashboard_interfaces = json.loads(os.environ.get("DASHBOARD_INTERFACES", "[]"))
except json.JSONDecodeError:
    dashboard_interfaces = []

interface_role_map = {}
for interface in dashboard_interfaces:
    if not isinstance(interface, dict):
        continue
    device = interface.get("device")
    role = interface.get("role") or device
    if device:
        interface_role_map[device] = role

original_handle_fail2ban_status = module.RouterAPIHandler.handle_fail2ban_status


def handle_interface_stats(self):
    try:
        interfaces = {}
        net_path = module.Path("/sys/class/net")

        for iface_path in net_path.iterdir():
            name = iface_path.name
            if name.startswith(("lo", "docker", "veth", "br-", "virbr")):
                continue

            stats_path = iface_path / "statistics"
            if not stats_path.exists():
                continue

            rx_bytes = int(self.read_file(stats_path / "rx_bytes") or 0)
            tx_bytes = int(self.read_file(stats_path / "tx_bytes") or 0)
            rx_rate, tx_rate = self.calculate_rates(name, rx_bytes, tx_bytes)
            ipv4 = self.get_ipv4(name)
            ipv6_list = self.get_ipv6(name)
            key = interface_role_map.get(name, name)

            interfaces[key] = {
                "device": name,
                "state": self.read_file(iface_path / "operstate").strip().upper() or "UNKNOWN",
                "ipv4": ipv4,
                "ipv6": ipv6_list,
                "rx_bytes": rx_bytes,
                "tx_bytes": tx_bytes,
                "rx_rate": rx_rate,
                "tx_rate": tx_rate,
                "rx_packets": int(self.read_file(stats_path / "rx_packets") or 0),
                "tx_packets": int(self.read_file(stats_path / "tx_packets") or 0),
                "rx_errors": int(self.read_file(stats_path / "rx_errors") or 0),
                "tx_errors": int(self.read_file(stats_path / "tx_errors") or 0),
            }

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
            print(f"Error running conntrack: {exc}")
            pass

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
            print(f"Error getting packet counters: {exc}")
            pass

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
                print(f"Fail2ban snapshot file NOT FOUND at: {FAIL2BAN_STATUS_FILE}")
        except FileNotFoundError:
            pass
        except Exception as exc:
            print(f"Error reading fail2ban snapshot: {exc}")
            pass

    print("Falling back to original handle_fail2ban_status (sudo)")
    return original_handle_fail2ban_status(self)


module.RouterAPIHandler.handle_interface_stats = handle_interface_stats
module.RouterAPIHandler.handle_firewall_stats = handle_firewall_stats
module.RouterAPIHandler.handle_caddy_status = handle_caddy_status
module.RouterAPIHandler.handle_fail2ban_status = handle_fail2ban_status

if __name__ == "__main__":
    module.run_server()
