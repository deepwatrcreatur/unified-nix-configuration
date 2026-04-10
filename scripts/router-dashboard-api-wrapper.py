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
                "state": (self.read_file(iface_path / "operstate") or "").strip().upper() or "UNKNOWN",
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


def handle_fail2ban_status(self):
    if FAIL2BAN_STATUS_FILE:
        try:
            with open(FAIL2BAN_STATUS_FILE, "r", encoding="utf-8") as handle:
                payload = json.load(handle)
            self.send_json(payload)
            return
        except FileNotFoundError:
            pass
        except Exception:
            pass

    return original_handle_fail2ban_status(self)


module.RouterAPIHandler.handle_interface_stats = handle_interface_stats
module.RouterAPIHandler.handle_fail2ban_status = handle_fail2ban_status

if __name__ == "__main__":
    module.run_server()
