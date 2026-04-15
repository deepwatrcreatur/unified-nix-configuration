# pkgs/mem0ai.nix
# mem0ai — semantic long-term memory layer for AI agents
# https://github.com/mem0ai/mem0
#
# Core dependencies only (no graph/extras).  Configured for local use with
# an Ollama-compatible LLM + Qdrant-in-process vector store.
{
  lib,
  python3Packages,
  fetchurl,
}:

python3Packages.buildPythonPackage {
  pname = "mem0ai";
  version = "1.0.11";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/py3/m/mem0ai/mem0ai-1.0.11-py3-none-any.whl";
    hash = "sha256-vPTWeNwKTU6OzK6+BVYurgIvzcgloOMJXQLyjPYaW20=";
  };

  propagatedBuildInputs = with python3Packages; [
    openai
    posthog
    protobuf
    pydantic
    pytz
    qdrant-client
    sqlalchemy
  ];

  # Wheel install; no build step needed.
  doCheck = false;

  meta = {
    description = "Semantic long-term memory layer for AI agents";
    longDescription = ''
      mem0ai provides a graph+vector store that agents use to persist and
      query factual knowledge across sessions.  In local mode it uses Qdrant
      (in-process) for vector similarity and SQLite for relational storage.

      Typical local config (Ollama LLM + local embeddings):
        from mem0 import Memory
        m = Memory.from_config({
          "llm": {"provider": "ollama", "config": {"model": "llama3.2"}},
          "embedder": {"provider": "ollama", "config": {"model": "nomic-embed-text"}},
          "vector_store": {"provider": "qdrant", "config": {"collection_name": "fleet-memory"}},
        })
    '';
    homepage = "https://github.com/mem0ai/mem0";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
    mainProgram = "mem0";
  };
}
