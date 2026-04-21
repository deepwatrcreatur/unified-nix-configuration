# overlays/flake-inputs.nix
# Overlays from external flake inputs
{ inputs }:

[
  # LLM/AI coding agents from numtide (claude-code, opencode, codex, rtk, etc.)
  inputs.llm-agents.overlays.default

  # Patch Codex to use the Nix store bubblewrap path on Linux instead of the
  # FHS-specific /usr/bin/bwrap probe used upstream.
  (final: prev: {
    llm-agents = prev.llm-agents // {
      codex = prev.llm-agents.codex.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            substituteInPlace \
              core/src/config/mod.rs \
              core/src/config/config_tests.rs \
              linux-sandbox/src/launcher.rs \
              --replace-fail '"/usr/bin/bwrap"' '"${final.bubblewrap}/bin/bwrap"'
          '';
      });
    };
  })

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
