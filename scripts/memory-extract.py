#!/usr/bin/env python3
"""
memory-extract.py — cross-agent memory extraction pipeline.

Extracts technical findings from Claude Code session logs and archives them
into docs/memory/ as structured markdown files.

Usage:
  python3 scripts/memory-extract.py [--project DIR] [--since DAYS] [--dry-run]

Arguments:
  --project DIR   Claude project dir to scan (default: all under ~/.claude/projects/)
  --since DAYS    Only process sessions from the last N days (default: 30)
  --dry-run       Print findings without writing files
  --min-score N   Minimum relevance score to include a finding (default: 2)

Output:
  docs/memory/<date>-<session-prefix>.md   One file per session with findings

Credentials filter:
  Lines matching secret/token/password/key patterns are redacted automatically.
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# ── Heuristic patterns ────────────────────────────────────────────────────────

# Phrases that indicate a technical finding in assistant text
FINDING_PATTERNS = [
    r"(?i)the (issue|problem|root cause|fix) (is|was|turned out)",
    r"(?i)i found (that|the|a)",
    r"(?i)note (that|:)",
    r"(?i)important[:\s]",
    r"(?i)this (is|was) (caused|fixed|resolved) by",
    r"(?i)(nixos|nix|systemd|kernel|service)\s+\w+\s+(requires|needs|expects|fails|errors)",
    r"(?i)error:\s+.{10,}",
    r"(?i)the (correct|right|proper) (way|approach|pattern|fix)",
    r"(?i)(must|should|needs to)\s+be\s+(set|configured|enabled|disabled)",
    r"(?i)(hash|sha256|rev)\s*[:=]\s*[a-f0-9A-F]{10,}",
    r"(?i)(module|option|attribute)\s+\w[\w.]+\s+(is|was|requires|must)",
]

COMPILED_PATTERNS = [re.compile(p) for p in FINDING_PATTERNS]

# Credentials filter — redact matching lines
CREDENTIAL_PATTERNS = [
    re.compile(r"(?i)(secret|token|password|api.key|private.key|auth.key)\s*[:=]\s*\S+"),
    re.compile(r"(?i)ssh-[a-z0-9]+\s+[A-Za-z0-9+/]{20,}"),
    re.compile(r"(?i)age[0-9a-z]{50,}"),
    re.compile(r"(?i)ghp_[A-Za-z0-9]{36,}"),
    re.compile(r"(?i)AKIA[A-Z0-9]{16}"),
]


def redact_credentials(text: str) -> str:
    for pat in CREDENTIAL_PATTERNS:
        text = pat.sub("[REDACTED]", text)
    return text


def score_finding(text: str) -> int:
    """Return relevance score (0-N); higher = more likely to be a technical finding."""
    score = 0
    for pat in COMPILED_PATTERNS:
        if pat.search(text):
            score += 1
    # Bonus for NixOS-specific content
    if any(kw in text for kw in ("nixpkgs", "nixosModule", "flake.nix", "home-manager", "systemd")):
        score += 1
    return score


def extract_text_from_message(message: dict) -> str:
    """Pull plain text from a Claude assistant message dict."""
    content = message.get("content", "")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                parts.append(item.get("text", ""))
        return "\n".join(parts)
    return ""


def extract_findings(session_path: Path, min_score: int = 2) -> list[dict]:
    """Return list of {timestamp, role, text, score} dicts from a session."""
    findings = []
    try:
        with open(session_path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue

                entry_type = entry.get("type")
                if entry_type not in ("user", "assistant"):
                    continue

                raw_text = extract_text_from_message(entry.get("message", {}))
                if len(raw_text) < 80:
                    continue

                clean_text = redact_credentials(raw_text)
                score = score_finding(clean_text)

                if score >= min_score:
                    findings.append({
                        "timestamp": entry.get("timestamp", 0),
                        "role": entry_type,
                        "text": clean_text[:2000],  # cap at 2 kB per finding
                        "score": score,
                    })
    except (OSError, UnicodeDecodeError):
        pass
    return findings


def session_date(session_path: Path) -> datetime:
    """Best-effort session date from mtime."""
    return datetime.fromtimestamp(session_path.stat().st_mtime, tz=timezone.utc)


def write_archive(
    output_dir: Path,
    session_path: Path,
    findings: list[dict],
    project_name: str,
    dry_run: bool,
) -> Path | None:
    """Write findings to a markdown file in docs/memory/."""
    if not findings:
        return None

    date_str = session_date(session_path).strftime("%Y-%m-%d")
    session_id = session_path.stem[:8]
    out_path = output_dir / f"{date_str}-{session_id}-{project_name}.md"

    # Sort by score descending then timestamp
    findings_sorted = sorted(findings, key=lambda x: (-x["score"], x["timestamp"]))

    lines = [
        f"# Memory Archive: {project_name} / {session_id}",
        f"",
        f"**Source**: `{session_path}`  ",
        f"**Date**: {date_str}  ",
        f"**Findings**: {len(findings)}",
        f"",
        f"---",
        f"",
    ]

    for i, f in enumerate(findings_sorted, 1):
        ts_raw = f["timestamp"]
        try:
            ts = datetime.fromtimestamp(int(ts_raw) / 1000, tz=timezone.utc).isoformat() if ts_raw else "?"
        except (TypeError, ValueError, OSError):
            ts = str(ts_raw)
        lines += [
            f"## Finding {i} (score={f['score']}, role={f['role']}, ts={ts})",
            f"",
            f"{f['text']}",
            f"",
            f"---",
            f"",
        ]

    content = "\n".join(lines)

    if dry_run:
        print(f"[dry-run] would write {out_path} ({len(findings)} findings)")
        return out_path

    output_dir.mkdir(parents=True, exist_ok=True)
    out_path.write_text(content)
    return out_path


# ── Main ─────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="Extract technical findings from agent sessions")
    parser.add_argument("--project", help="Claude project dir path (default: all)")
    parser.add_argument("--since", type=int, default=30, help="Days to look back (default: 30)")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--min-score", type=int, default=2)
    args = parser.parse_args()

    claude_dir = Path.home() / ".claude"
    projects_dir = claude_dir / "projects"
    repo_root = Path(__file__).parent.parent
    output_dir = repo_root / "docs" / "memory"

    if not projects_dir.exists():
        print(f"error: {projects_dir} not found", file=sys.stderr)
        return 1

    cutoff = datetime.now(tz=timezone.utc) - timedelta(days=args.since)

    # Collect session files to process
    session_files: list[tuple[Path, str]] = []
    if args.project:
        project_dir = Path(args.project)
        if not project_dir.exists():
            print(f"error: {project_dir} not found", file=sys.stderr)
            return 1
        for f in project_dir.glob("*.jsonl"):
            session_files.append((f, project_dir.name))
    else:
        for project_dir in projects_dir.iterdir():
            if not project_dir.is_dir():
                continue
            for f in project_dir.glob("*.jsonl"):
                session_files.append((f, project_dir.name[-30:]))  # truncate long names

    # Filter by date
    recent = [(f, p) for f, p in session_files if session_date(f) >= cutoff]
    print(f"Found {len(recent)} session files in the last {args.since} days")

    total_findings = 0
    written = []

    for session_path, project_name in sorted(recent, key=lambda x: session_date(x[0])):
        findings = extract_findings(session_path, min_score=args.min_score)
        if not findings:
            continue

        out = write_archive(output_dir, session_path, findings, project_name, args.dry_run)
        if out:
            total_findings += len(findings)
            written.append(out)
            print(f"  {'[dry]' if args.dry_run else '[wrote]'} {out.name} ({len(findings)} findings)")

    print(f"\nTotal: {total_findings} findings across {len(written)} sessions")
    if not args.dry_run and written:
        print(f"Archive: {output_dir}/")
        print("Index these with: qmd index docs/memory/")

    return 0


if __name__ == "__main__":
    sys.exit(main())
