# overlays/flake-inputs.nix
# Overlays from external flake inputs
{ inputs }:

[
  # LLM/AI coding agents from numtide (claude-code, opencode, codex, rtk, etc.)
  inputs.llm-agents.overlays.default

  # Worktrunk (git worktree management for parallel agents)
  (final: prev: {
    worktrunk = inputs.worktrunk.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # Lightpanda headless browser for AI agents
  inputs.nix-lightpanda.overlays.default

  # markit - universal document-to-markdown converter CLI
  inputs.nix-markit.overlays.default

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
