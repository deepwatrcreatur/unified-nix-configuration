# overlays/flake-inputs.nix
# Overlays from external flake inputs
{ inputs }:

[
  # Worktrunk (git worktree management for parallel agents)
  (final: prev: {
    worktrunk = inputs.worktrunk.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # Opencode CLI from nixpkgs-unstable (v1.2.13)
  # The fnox wrappers (opencode-zai, opencode-claude) automatically use this opencode.
  (final: prev: {
    opencode = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.opencode;
  })

  # Lightpanda headless browser for AI agents
  inputs.nix-lightpanda.overlays.default

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
]
