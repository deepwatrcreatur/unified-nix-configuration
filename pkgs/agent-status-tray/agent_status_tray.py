#!/usr/bin/env python3

import json
import os
import sqlite3
import subprocess
import threading
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("AyatanaAppIndicator3", "0.1")

from gi.repository import AyatanaAppIndicator3, GLib, Gtk


CONFIG_PATH = Path(os.environ.get("AGENT_STATUS_TRAY_CONFIG", Path.home() / ".config/agent-status-tray/config.json"))
CACHE_PATH = Path(os.environ.get("AGENT_STATUS_TRAY_CACHE", Path.home() / ".cache/agent-status-tray/status.json"))


def read_json(path: Path) -> Any | None:
    try:
        return json.loads(path.read_text())
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return None


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True))


def run_command(args: list[str], timeout: int = 8) -> tuple[int, str, str]:
    try:
        proc = subprocess.run(
            args,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
        return proc.returncode, proc.stdout.strip(), proc.stderr.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired) as err:
        return 127, "", str(err)


def command_exists(command: str) -> bool:
    return run_command(["bash", "-lc", f"command -v {command} >/dev/null 2>&1"])[0] == 0


def format_percent(value: Any) -> str:
    try:
        return f"{round(float(value))}%"
    except (TypeError, ValueError):
        return "?"


def format_timestamp(value: str | None) -> str | None:
    if not value:
        return None
    try:
        normalized = value.replace("Z", "+00:00")
        parsed = datetime.fromisoformat(normalized)
        return parsed.astimezone().strftime("%b %d %I:%M%p").lower()
    except ValueError:
        return value


def format_relative(value: str | None) -> str | None:
    if not value:
        return None
    try:
        normalized = value.replace("Z", "+00:00")
        parsed = datetime.fromisoformat(normalized)
        seconds = int((parsed - datetime.now(timezone.utc)).total_seconds())
    except ValueError:
        return None

    if seconds <= 0:
        return "now"
    if seconds < 3600:
        return f"{seconds // 60}m"
    if seconds < 86400:
        hours = seconds // 3600
        minutes = (seconds % 3600) // 60
        return f"{hours}h {minutes}m"
    days = seconds // 86400
    hours = (seconds % 86400) // 3600
    return f"{days}d {hours}h"


def flatten_output(stdout: str, stderr: str) -> str:
    output = stdout.strip() or stderr.strip()
    return " ".join(output.split())


@dataclass
class AgentDefinition:
    id: str
    name: str
    command: str


class AgentStatusCollector:
    def __init__(self, config: dict[str, Any]) -> None:
        self.config = config
        self.home = Path.home()
        self.codex_dir = self.home / ".codex"
        self.claude_dir = self.home / ".claude"
        self.gemini_dir = self.home / ".gemini"
        self.copilot_dir = self.home / ".copilot"

    def collect(self) -> dict[str, Any]:
        definitions = [AgentDefinition(**agent) for agent in self.config.get("agents", [])]
        statuses = [self.collect_agent(agent) for agent in definitions]
        snapshot = {
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "label": self.build_label(statuses),
            "tooltip": self.build_tooltip(statuses),
            "agents": statuses,
        }
        write_json(CACHE_PATH, snapshot)
        return snapshot

    def collect_agent(self, agent: AgentDefinition) -> dict[str, Any]:
        base = {
            "id": agent.id,
            "name": agent.name,
            "command": agent.command,
            "installed": command_exists(agent.command),
            "state": "unknown",
            "summary": "No status available",
            "details": [],
            "metrics": {},
        }
        if not base["installed"]:
            base["state"] = "missing"
            base["summary"] = f"{agent.command} not found on PATH"
            return base

        try:
            handler = getattr(self, f"collect_{agent.id}", self.collect_generic)
            return handler(agent, base)
        except Exception as err:  # noqa: BLE001
            base["state"] = "error"
            base["summary"] = f"Collector failed: {err}"
            return base

    def collect_generic(self, agent: AgentDefinition, base: dict[str, Any]) -> dict[str, Any]:
        base["state"] = "installed"
        base["summary"] = f"{agent.command} installed"
        return base

    def collect_codex(self, agent: AgentDefinition, base: dict[str, Any]) -> dict[str, Any]:
        rc, stdout, stderr = run_command(["codex", "login", "status"])
        auth = read_json(self.codex_dir / "auth.json") or {}
        summary = flatten_output(stdout, stderr) if rc == 0 else "Unable to read login status"
        last_refresh = format_timestamp(auth.get("last_refresh"))

        thread_count = None
        state_db = self.codex_dir / "state_5.sqlite"
        if state_db.exists():
            try:
                with sqlite3.connect(state_db) as conn:
                    row = conn.execute("select count(*) from threads").fetchone()
                    thread_count = int(row[0]) if row else None
            except sqlite3.Error:
                thread_count = None

        details = []
        if auth.get("auth_mode"):
            details.append(f"Auth mode: {auth['auth_mode']}")
        if last_refresh:
            details.append(f"Token refresh: {last_refresh}")
        if thread_count is not None:
            details.append(f"Local sessions: {thread_count}")

        base["state"] = "ready" if rc == 0 else "warning"
        base["summary"] = summary
        base["details"] = details
        return base

    def collect_claude(self, agent: AgentDefinition, base: dict[str, Any]) -> dict[str, Any]:
        token = self.get_claude_oauth_token()
        if not token:
            base["state"] = "warning"
            base["summary"] = "Claude is installed but no OAuth token was found"
            return base

        usage = self.fetch_claude_usage(token)
        if not usage:
            base["state"] = "warning"
            base["summary"] = "Claude token found, but usage endpoint did not respond"
            return base

        current = usage.get("five_hour", {})
        weekly = usage.get("seven_day", {})
        extra = usage.get("extra_usage", {})
        current_pct = round(float(current.get("utilization", 0)))
        weekly_pct = round(float(weekly.get("utilization", 0)))

        details = [
            f"Current window: {current_pct}% used, resets {format_timestamp(current.get('resets_at')) or 'unknown'}",
            f"Weekly window: {weekly_pct}% used, resets {format_timestamp(weekly.get('resets_at')) or 'unknown'}",
        ]

        if extra.get("is_enabled"):
            details.append(
                "Extra credits: ${:.2f}/${:.2f}".format(
                    float(extra.get("used_credits", 0)) / 100,
                    float(extra.get("monthly_limit", 0)) / 100,
                )
            )

        base["state"] = "ready"
        base["summary"] = f"Current {current_pct}% • Weekly {weekly_pct}%"
        base["details"] = details
        base["metrics"] = {
            "current_utilization": current_pct,
            "current_resets_at": current.get("resets_at"),
            "weekly_utilization": weekly_pct,
            "weekly_resets_at": weekly.get("resets_at"),
        }
        if extra.get("is_enabled"):
            base["metrics"]["extra_usage"] = {
                "used_usd": float(extra.get("used_credits", 0)) / 100,
                "limit_usd": float(extra.get("monthly_limit", 0)) / 100,
            }
        return base

    def collect_gemini(self, agent: AgentDefinition, base: dict[str, Any]) -> dict[str, Any]:
        accounts = read_json(self.gemini_dir / "google_accounts.json") or {}
        active = accounts.get("active")
        rc, stdout, stderr = run_command(["gemini", "--list-sessions", "--output-format", "json"], timeout=10)
        session_count = None
        if rc == 0 and stdout:
            try:
                payload = json.loads(stdout)
                if isinstance(payload, list):
                    session_count = len(payload)
                elif isinstance(payload, dict):
                    for key in ("sessions", "items", "data"):
                        if isinstance(payload.get(key), list):
                            session_count = len(payload[key])
                            break
            except json.JSONDecodeError:
                session_count = None

        if session_count is None:
            text = flatten_output(stdout, stderr)
            if "Available sessions" in text:
                try:
                    session_count = int(text.split("(")[1].split(")")[0])
                except (IndexError, ValueError):
                    session_count = None

        details = []
        if active:
            details.append(f"Active account: {active}")
        if session_count is not None:
            details.append(f"Local sessions: {session_count}")

        base["state"] = "ready" if active else "installed"
        base["summary"] = "Signed in" if active else "Installed"
        if session_count is not None:
            base["summary"] += f" • {session_count} sessions"
        base["details"] = details
        return base

    def collect_cursor(self, agent: AgentDefinition, base: dict[str, Any]) -> dict[str, Any]:
        rc, stdout, stderr = run_command(["cursor-agent", "status"])
        summary = flatten_output(stdout, stderr)
        base["state"] = "ready" if rc == 0 and "not logged in" not in summary.lower() else "warning"
        base["summary"] = summary or "Cursor status unavailable"
        return base

    def collect_copilot(self, agent: AgentDefinition, base: dict[str, Any]) -> dict[str, Any]:
        config = read_json(self.copilot_dir / "config.json") or {}
        details = []
        user = config.get("last_logged_in_user")
        if user:
            details.append(f"Last logged-in user: {user}")

        session_state_dir = self.copilot_dir / "session-state"
        session_count = len(list(session_state_dir.glob("*.jsonl"))) if session_state_dir.exists() else 0
        details.append(f"Local sessions: {session_count}")

        base["state"] = "ready" if user else "installed"
        base["summary"] = f"{'Signed in' if user else 'Installed'} • {session_count} sessions"
        base["details"] = details
        return base

    def collect_factory(self, agent: AgentDefinition, base: dict[str, Any]) -> dict[str, Any]:
        base["state"] = "installed"
        base["summary"] = "Factory Droid installed"
        return base

    def build_label(self, statuses: list[dict[str, Any]]) -> str:
        claude = next((status for status in statuses if status["id"] == "claude"), None)
        if claude and "current_utilization" in claude.get("metrics", {}):
            return f"AI {claude['metrics']['current_utilization']}%"

        ready = sum(1 for status in statuses if status["state"] in {"ready", "installed"})
        return f"AI {ready}/{len(statuses)}"

    def build_tooltip(self, statuses: list[dict[str, Any]]) -> str:
        lines = []
        for status in statuses:
            lines.append(f"{status['name']}: {status['summary']}")
        return "\n".join(lines)

    def get_claude_oauth_token(self) -> str | None:
        env_token = os.environ.get("CLAUDE_CODE_OAUTH_TOKEN")
        if env_token:
            return env_token

        credentials = read_json(self.claude_dir / ".credentials.json") or {}
        oauth = credentials.get("claudeAiOauth", {})
        token = oauth.get("accessToken")
        return token or None

    def fetch_claude_usage(self, token: str) -> dict[str, Any] | None:
        cache_file = CACHE_PATH.parent / "claude-usage.json"
        cache_ttl = int(self.config.get("claude_cache_ttl_seconds", 60))
        cached = read_json(cache_file)
        now = time.time()
        if cached and (now - cached.get("_fetched_at", 0)) < cache_ttl:
            return cached.get("payload")

        request = urllib.request.Request(
            "https://api.anthropic.com/api/oauth/usage",
            headers={
                "Accept": "application/json",
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}",
                "anthropic-beta": "oauth-2025-04-20",
                "User-Agent": "agent-status-tray/0.1",
            },
        )

        try:
            with urllib.request.urlopen(request, timeout=5) as response:
                payload = json.loads(response.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
            return cached.get("payload") if cached else None

        write_json(cache_file, {"_fetched_at": now, "payload": payload})
        return payload


class AgentStatusTray:
    def __init__(self, config: dict[str, Any]) -> None:
        self.config = config
        self.collector = AgentStatusCollector(config)
        self.indicator = AyatanaAppIndicator3.Indicator.new(
            "agent-status-tray",
            "utilities-terminal",
            AyatanaAppIndicator3.IndicatorCategory.APPLICATION_STATUS,
        )
        self.indicator.set_status(AyatanaAppIndicator3.IndicatorStatus.ACTIVE)
        self.indicator.set_menu(Gtk.Menu())
        self.indicator.set_title("Agent Status")
        self.current_snapshot = read_json(CACHE_PATH) or {
            "label": "AI ...",
            "tooltip": "Loading agent status...",
            "agents": [],
        }
        self.refresh_interval_seconds = int(config.get("refresh_interval_seconds", 90))
        self.render(self.current_snapshot)

    def start(self) -> None:
        GLib.idle_add(self.refresh_async)
        GLib.timeout_add_seconds(self.refresh_interval_seconds, self.refresh_async)
        Gtk.main()

    def refresh_async(self) -> bool:
        thread = threading.Thread(target=self.refresh_snapshot, daemon=True)
        thread.start()
        return True

    def refresh_snapshot(self) -> None:
        snapshot = self.collector.collect()
        GLib.idle_add(self.render, snapshot)

    def render(self, snapshot: dict[str, Any]) -> bool:
        self.current_snapshot = snapshot
        self.indicator.set_label(snapshot.get("label", "AI"), "agent-status")
        self.indicator.set_icon_full("utilities-terminal", snapshot.get("tooltip", "Agent Status"))
        self.indicator.set_menu(self.build_menu(snapshot))
        return False

    def build_menu(self, snapshot: dict[str, Any]) -> Gtk.Menu:
        menu = Gtk.Menu()

        menu.append(self.disabled_item(snapshot.get("label", "Agent Status")))
        generated = format_timestamp(snapshot.get("generated_at"))
        if generated:
            menu.append(self.disabled_item(f"Updated {generated}"))
        menu.append(Gtk.SeparatorMenuItem())

        for agent in snapshot.get("agents", []):
            menu.append(self.disabled_item(f"{agent['name']}: {agent['summary']}"))
            for detail in agent.get("details", []):
                menu.append(self.disabled_item(f"  {detail}"))
            reset_at = agent.get("metrics", {}).get("current_resets_at")
            if reset_at:
                relative = format_relative(reset_at)
                if relative:
                    menu.append(self.disabled_item(f"  Current reset in {relative}"))
            menu.append(Gtk.SeparatorMenuItem())

        refresh_item = Gtk.MenuItem(label="Refresh Now")
        refresh_item.connect("activate", lambda *_args: self.refresh_async())
        menu.append(refresh_item)

        open_cache_item = Gtk.MenuItem(label="Open Cache JSON")
        open_cache_item.connect("activate", self.open_cache)
        menu.append(open_cache_item)

        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", lambda *_args: Gtk.main_quit())
        menu.append(quit_item)

        menu.show_all()
        return menu

    def open_cache(self, *_args: Any) -> None:
        run_command(["xdg-open", str(CACHE_PATH)], timeout=3)

    @staticmethod
    def disabled_item(label: str) -> Gtk.MenuItem:
        item = Gtk.MenuItem(label=label)
        item.set_sensitive(False)
        return item


def main() -> int:
    config = read_json(CONFIG_PATH) or {"agents": []}
    tray = AgentStatusTray(config)
    tray.start()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
