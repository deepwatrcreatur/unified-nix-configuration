#!/usr/bin/env python3
"""
mem0-bootstrap.py — ingest fleet knowledge docs into the Mem0 semantic store.

Usage:
  python3 scripts/mem0-bootstrap.py [--dry-run] [--ollama-url URL]

Reads AGENTS.md and CLAUDE.md from the repo root (and ~/.claude/CLAUDE.md if
present), extracts factual knowledge, and stores it in Mem0 under the agent
id "fleet-bootstrap".

Configuration (environment variables):
  MEM0_OLLAMA_URL      Ollama base URL (default: http://localhost:11434)
  MEM0_LLM_MODEL       Ollama model for fact extraction (default: llama3.2)
  MEM0_EMBED_MODEL     Ollama embedding model (default: nomic-embed-text)
  MEM0_COLLECTION      Qdrant collection name (default: fleet-memory)
  MEM0_DB_PATH         SQLite path for Mem0 history (default: ~/.local/share/mem0/fleet.db)

Prerequisites:
  - Ollama running with llama3.2 and nomic-embed-text pulled
  - mem0ai installed (via `nix shell` or home-manager package)
  - qdrant-client installed (bundled with mem0ai deps)
"""

import argparse
import os
import sys
from pathlib import Path

# ── Configuration ────────────────────────────────────────────────────────────

OLLAMA_URL = os.environ.get("MEM0_OLLAMA_URL", "http://localhost:11434")
LLM_MODEL = os.environ.get("MEM0_LLM_MODEL", "llama3.2")
EMBED_MODEL = os.environ.get("MEM0_EMBED_MODEL", "nomic-embed-text")
COLLECTION = os.environ.get("MEM0_COLLECTION", "fleet-memory")
DB_PATH = os.environ.get("MEM0_DB_PATH", str(Path.home() / ".local/share/mem0/fleet.db"))

MEM0_CONFIG = {
    "llm": {
        "provider": "ollama",
        "config": {
            "model": LLM_MODEL,
            "ollama_base_url": OLLAMA_URL,
        },
    },
    "embedder": {
        "provider": "ollama",
        "config": {
            "model": EMBED_MODEL,
            "ollama_base_url": OLLAMA_URL,
        },
    },
    "vector_store": {
        "provider": "qdrant",
        "config": {
            "collection_name": COLLECTION,
            "on_disk": True,
            "path": str(Path.home() / ".local/share/mem0/qdrant"),
        },
    },
    "history_db_path": DB_PATH,
}

# ── Core Fact Schema ─────────────────────────────────────────────────────────
#
# Facts are stored with these metadata keys to allow targeted retrieval:
#   category: one of hosts | ips | secrets-policy | shell-prefs | agent-prefs
#   source: the file the fact was extracted from

AGENT_ID = "fleet-bootstrap"

# ── Source documents ─────────────────────────────────────────────────────────

def find_source_docs(repo_root: Path) -> list[tuple[str, str]]:
    """Return (label, content) pairs for all fleet knowledge docs."""
    candidates = [
        (repo_root / "AGENTS.md", "AGENTS.md"),
        (repo_root / "CLAUDE.md", "CLAUDE.md"),
        (Path.home() / ".claude/CLAUDE.md", "~/.claude/CLAUDE.md"),
        (Path.home() / ".claude/RTK.md", "~/.claude/RTK.md"),
    ]
    docs = []
    for path, label in candidates:
        if path.exists():
            docs.append((label, path.read_text()))
            print(f"  [found] {label} ({len(path.read_text())} chars)")
        else:
            print(f"  [skip ] {label} (not found)")
    return docs


# ── Chunking ─────────────────────────────────────────────────────────────────

def chunk_by_section(content: str, max_chars: int = 1500) -> list[str]:
    """Split markdown content at ## headings, keeping chunks under max_chars."""
    chunks: list[str] = []
    current: list[str] = []
    current_len = 0

    for line in content.splitlines():
        if line.startswith("## ") and current_len > 200:
            chunks.append("\n".join(current))
            current = [line]
            current_len = len(line)
        else:
            current.append(line)
            current_len += len(line) + 1
            if current_len > max_chars:
                chunks.append("\n".join(current))
                current = []
                current_len = 0

    if current:
        chunks.append("\n".join(current))

    return [c for c in chunks if len(c.strip()) > 50]


# ── Main ─────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="Bootstrap Mem0 fleet memory store")
    parser.add_argument("--dry-run", action="store_true", help="Parse docs but do not store")
    parser.add_argument("--ollama-url", default=OLLAMA_URL, help="Ollama base URL")
    args = parser.parse_args()

    # Allow command-line override
    if args.ollama_url != OLLAMA_URL:
        MEM0_CONFIG["llm"]["config"]["ollama_base_url"] = args.ollama_url
        MEM0_CONFIG["embedder"]["config"]["ollama_base_url"] = args.ollama_url

    try:
        from mem0 import Memory  # type: ignore[import]
    except ImportError:
        print("error: mem0ai not installed. Run: nix shell .#mem0-env", file=sys.stderr)
        return 1

    repo_root = Path(__file__).parent.parent
    print("mem0-bootstrap: ingesting fleet knowledge docs")
    print(f"  repo root   : {repo_root}")
    print(f"  ollama url  : {MEM0_CONFIG['llm']['config']['ollama_base_url']}")
    print(f"  llm model   : {LLM_MODEL}")
    print(f"  embed model : {EMBED_MODEL}")
    print(f"  collection  : {COLLECTION}")
    print()

    docs = find_source_docs(repo_root)
    if not docs:
        print("warning: no source docs found; nothing to ingest")
        return 0

    if args.dry_run:
        total_chunks = sum(len(chunk_by_section(content)) for _, content in docs)
        print(f"[dry-run] would ingest {len(docs)} docs → {total_chunks} chunks")
        return 0

    # Ensure DB directory exists
    Path(DB_PATH).parent.mkdir(parents=True, exist_ok=True)

    print("initialising Mem0 store...")
    m = Memory.from_config(MEM0_CONFIG)

    total = 0
    for label, content in docs:
        chunks = chunk_by_section(content)
        print(f"ingesting {label}: {len(chunks)} chunks")
        for i, chunk in enumerate(chunks, 1):
            m.add(
                [{"role": "user", "content": chunk}],
                agent_id=AGENT_ID,
                metadata={"source": label, "chunk": i},
            )
            total += 1
            print(f"  chunk {i}/{len(chunks)}", end="\r")
        print()

    print(f"\ndone: {total} chunks ingested from {len(docs)} docs")
    print(f"store: {DB_PATH}")
    print()
    print("Query examples:")
    print("  python3 -c \"from mem0 import Memory; m=Memory.from_config(...); print(m.search('What is the router IP?', agent_id='fleet-bootstrap'))\"")
    return 0


if __name__ == "__main__":
    sys.exit(main())
