#!/usr/bin/env python3
import grp
import json
import os
import subprocess
import sys
import tempfile


def log_warning(message):
    print(message, file=sys.stderr, flush=True)


def get_required_env(name):
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"Missing required environment variable: {name}")
    return value


FAIL2BAN_CLIENT = get_required_env("DASHBOARD_FAIL2BAN_CLIENT")
OUTPUT_PATH = get_required_env("DASHBOARD_FAIL2BAN_STATUS_FILE")
OUTPUT_GROUP = os.environ.get("DASHBOARD_FAIL2BAN_STATUS_GROUP", "router-dashboard").strip() or "router-dashboard"


def build_payload():
    try:
        result = subprocess.run(
            [FAIL2BAN_CLIENT, "status"],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return {
            "available": False,
            "message": f"Failed to execute fail2ban-client: {exc}",
        }

    if result.returncode != 0:
        return {
            "available": False,
            "message": result.stderr.strip() or result.stdout.strip() or "Failed to get fail2ban status",
        }

    jails = []
    for line in result.stdout.splitlines():
        if "Jail list:" in line:
            jail_names = line.split(":", 1)[1].strip().split(", ")
            jails = [jail.strip() for jail in jail_names if jail.strip()]
            break

    jail_stats = []
    total_banned = 0
    all_banned_ips = []

    for jail in jails:
        try:
            jail_result = subprocess.run(
                [FAIL2BAN_CLIENT, "status", jail],
                capture_output=True,
                text=True,
                timeout=5,
            )
        except (OSError, subprocess.SubprocessError) as exc:
            log_warning(f"Failed to query fail2ban jail {jail}: {exc}")
            continue
        if jail_result.returncode != 0:
            log_warning(f"fail2ban-client status {jail} failed: {jail_result.stderr.strip() or jail_result.stdout.strip()}")
            continue

        stats = {
            "name": jail,
            "currentlyFailed": 0,
            "totalFailed": 0,
            "currentlyBanned": 0,
            "totalBanned": 0,
            "bannedIPs": [],
        }

        for line in jail_result.stdout.splitlines():
            line = line.strip()
            if "Currently failed:" in line:
                stats["currentlyFailed"] = int(line.split(":", 1)[1].strip())
            elif "Total failed:" in line:
                stats["totalFailed"] = int(line.split(":", 1)[1].strip())
            elif "Currently banned:" in line:
                stats["currentlyBanned"] = int(line.split(":", 1)[1].strip())
            elif "Total banned:" in line:
                stats["totalBanned"] = int(line.split(":", 1)[1].strip())
            elif "Banned IP list:" in line:
                ip_list = line.split(":", 1)[1].strip()
                if ip_list:
                    stats["bannedIPs"] = ip_list.split()
                    all_banned_ips.extend(stats["bannedIPs"])

        total_banned += stats["currentlyBanned"]
        jail_stats.append(stats)

    return {
        "available": True,
        "jails": jail_stats,
        "totalCurrentlyBanned": total_banned,
        "allBannedIPs": sorted(set(all_banned_ips)),
    }


def main():
    payload = build_payload()
    output_dir = os.path.dirname(OUTPUT_PATH)
    os.makedirs(output_dir, mode=0o750, exist_ok=True)

    with tempfile.NamedTemporaryFile("w", dir=output_dir, delete=False, encoding="utf-8") as handle:
        json.dump(payload, handle)
        handle.write("\n")
        temp_path = handle.name

    gid = grp.getgrnam(OUTPUT_GROUP).gr_gid
    os.chown(temp_path, 0, gid)
    os.chmod(temp_path, 0o640)
    os.replace(temp_path, OUTPUT_PATH)


if __name__ == "__main__":
    main()
