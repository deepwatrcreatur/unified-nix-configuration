# overlays/flake-inputs.nix
# Overlays from external flake inputs
{ inputs }:

[
  # LLM/AI coding agents from numtide (claude-code, opencode, codex, rtk, etc.)
  inputs.llm-agents.overlays.default

  # Worktrunk (git worktree management for parallel agents)
  (final: prev: {
    worktrunk = final.callPackage ../pkgs/worktrunk.nix { };
  })

  # Lightpanda headless browser for AI agents
  (final: prev: {
    lightpanda = inputs.nix-lightpanda.packages.${prev.stdenv.hostPlatform.system}.lightpanda;
  })

  # markit - universal document-to-markdown converter CLI
  (final: prev: {
    markit = inputs.nix-markit.packages.${prev.stdenv.hostPlatform.system}.markit;
  })

  # Tesla inference overlays for GPU optimization
  inputs.tesla-inference-flake.overlays.ollama-official-binaries # Use official binaries to avoid cuda_compat build error
  inputs.tesla-inference-flake.overlays.llama-cpp-tesla
  inputs.tesla-inference-flake.overlays.gpu-tools

  # fnox - Try to use from nixpkgs first, fallback to flake input if not available
  (final: prev: {
    fnox =
      if prev.stdenv.isLinux && prev.stdenv.isx86_64 then
        (prev.fnox or inputs.fnox.packages.${prev.stdenv.hostPlatform.system}.default)
      else
        inputs.fnox.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # qmd - local document search CLI from its upstream flake
  (final: prev: {
    qmd = inputs.qmd.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # roundtable - autonomous multi-agent design orchestrator
  (final: prev: {
    roundtable = inputs.agent-roundtable.packages.${prev.stdenv.hostPlatform.system}.default;
    roundtable-web = inputs.agent-roundtable.packages.${prev.stdenv.hostPlatform.system}.roundtable-web;
  })

  # Keep the upstream beads_rust flake pinned for metadata and future source
  # packaging work. The repo-managed runtime package is defined in
  # overlays/packages.nix from release binaries instead of this upstream build,
  # because the upstream flake is currently not reproducible in this repo.
  (final: prev: {
    beads-rust-upstream = inputs.beads-rust.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # llama-cpp-python: override inherited dotted CUDA architectures with the
  # integer form expected by modern CMake/CUDA.
  (final: prev: {
    pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
      (pyFinal: pyPrev: {
        llama-cpp-python = pyPrev.llama-cpp-python.overrideAttrs (old: {
          cmakeFlags =
            let
              keepFlag =
                flag:
                !(prev.lib.hasPrefix "-DCMAKE_CUDA_ARCHITECTURES=" flag)
                && !(prev.lib.hasPrefix "-DGGML_CUDA_ARCHITECTURES=" flag);
            in
            builtins.filter keepFlag (old.cmakeFlags or [ ])
            ++ [ "-DCMAKE_CUDA_ARCHITECTURES=61;70;75;80;86;89;90" ];
        });
      })
    ];
  })
]
