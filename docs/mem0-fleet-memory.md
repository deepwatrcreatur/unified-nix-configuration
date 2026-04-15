# Mem0 Fleet Memory

`mem0` is the semantic long-term memory layer for the agent fleet.  It stores
factual knowledge extracted from infrastructure docs and answers natural-language
queries across sessions.

## What It Stores (Core Fact Schema)

| Category | Examples |
|---|---|
| `hosts` | Hostnames, machine roles, OS versions |
| `ips` | Static IPs, interface assignments |
| `secrets-policy` | Where secrets live, which tool manages them |
| `shell-prefs` | Default shell, key aliases, Fish vs Nushell |
| `agent-prefs` | RTK settings, hook configs, approved permissions |

**Not for:** raw session transcripts (use CASS), procedural playbooks (use CM).

## Installation

```bash
# Via home-manager (after rebuild):
programs.mem0.enable = true;  # coming once module is wired

# Via nix shell for ad-hoc use:
nix shell .#mem0-env
python3 --version   # confirms mem0ai is importable
```

Or run the bootstrap script directly with `nix shell`:

```bash
nix shell .#mem0-env --command python3 scripts/mem0-bootstrap.py
```

## Prerequisites

Mem0 in local mode uses Ollama for both LLM (fact extraction) and embeddings.
Pull the required models before bootstrapping:

```bash
ollama pull llama3.2          # fact extraction
ollama pull nomic-embed-text  # embeddings
```

The inference VM (`tesla-inference-flake`) has these models available.

## Bootstrap (Ingest Fleet Docs)

```bash
# Dry run first:
python3 scripts/mem0-bootstrap.py --dry-run

# Ingest into local store:
python3 scripts/mem0-bootstrap.py

# With custom Ollama URL (e.g. inference VM):
MEM0_OLLAMA_URL=http://10.10.10.18:11434 python3 scripts/mem0-bootstrap.py
```

This reads `AGENTS.md`, `CLAUDE.md`, and `~/.claude/CLAUDE.md`, splits them
into chunks, and stores them in a local Qdrant vector store under
`~/.local/share/mem0/`.

## Query Interface

```python
from mem0 import Memory

MEM0_CONFIG = {
    "llm": {
        "provider": "ollama",
        "config": {"model": "llama3.2", "ollama_base_url": "http://localhost:11434"},
    },
    "embedder": {
        "provider": "ollama",
        "config": {"model": "nomic-embed-text", "ollama_base_url": "http://localhost:11434"},
    },
    "vector_store": {
        "provider": "qdrant",
        "config": {
            "collection_name": "fleet-memory",
            "on_disk": True,
            "path": "~/.local/share/mem0/qdrant",
        },
    },
    "history_db_path": "~/.local/share/mem0/fleet.db",
}

m = Memory.from_config(MEM0_CONFIG)

# Search
results = m.search("What is the router IP address?", agent_id="fleet-bootstrap")
for r in results:
    print(r["memory"])

# Add a new fact
m.add(
    [{"role": "user", "content": "The homeserver is at 10.10.10.10 and runs NixOS."}],
    agent_id="fleet-bootstrap",
    metadata={"category": "hosts"},
)

# Get all stored facts
all_facts = m.get_all(agent_id="fleet-bootstrap")
```

## Agent Workflow

Agents should consult Mem0 before making infrastructure changes:

```python
# At the start of an agent session:
results = m.search("router configuration", agent_id="fleet-bootstrap", limit=5)
context = "\n".join(r["memory"] for r in results)
# Include context in first system message or tool call
```

After discovering new facts, store them:

```python
m.add(
    [{"role": "user", "content": "The new workstation hostname is phobos."}],
    agent_id="fleet-bootstrap",
    metadata={"category": "hosts"},
)
```

## Configuration (Environment Variables)

| Variable | Default | Description |
|---|---|---|
| `MEM0_OLLAMA_URL` | `http://localhost:11434` | Ollama base URL |
| `MEM0_LLM_MODEL` | `llama3.2` | Model for fact extraction |
| `MEM0_EMBED_MODEL` | `nomic-embed-text` | Embedding model |
| `MEM0_COLLECTION` | `fleet-memory` | Qdrant collection name |
| `MEM0_DB_PATH` | `~/.local/share/mem0/fleet.db` | SQLite history path |

## Relationship to Other Memory Layers

| Layer | What it stores | Tool |
|---|---|---|
| Mem0 | Facts, entities, infrastructure topology | `mem0ai` |
| CASS | Raw session transcripts for debugging | `cass-session-search` |
| CM | Procedural playbooks ("how to do X") | `cm-procedural-memory` |
| Claude memory | Per-user preferences and project notes | `~/.claude/projects/.../memory/` |
