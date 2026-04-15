# prototype/nix-agent-fleet/flake.nix
#
# Agent-tooling integration flake.
#
# Purpose: aggregate the "agent stack" inputs into a single consumable interface
# so that unified-nix-configuration can replace 8-10 individual inputs with one.
#
# Usage in unified-nix-configuration:
#
#   nix-agent-fleet.url = "github:deepwatrcreatur/nix-agent-fleet";
#   nix-agent-fleet.inputs.nixpkgs.follows = "nixpkgs";
#
# Then in overlays:
#
#   inputs.nix-agent-fleet.overlays.default
#
# And in home-manager:
#
#   imports = [ inputs.nix-agent-fleet.homeManagerModules.agent-stack ];
#
# Promotion path:
#   experimental → stable after the tool has been in use for ≥1 full release cycle
#   with no regressions and the module interface is considered stable.
#
{
  description = "Unified agent-tooling fleet: packages, overlays, and Home Manager modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Stable agent tools ────────────────────────────────────────────────────
    # Tools in daily use across all agents; interface considered stable.

    # Credential proxy used by all fnox-wrapped tools
    fnox = {
      url = "github:deepwatrcreatur/fnox-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # RTK hook integration (token-efficient Claude Code proxy + hooks)
    nix-rtk = {
      url = "github:deepwatrcreatur/nix-rtk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.llm-agents.follows = "llm-agents";
    };

    # LLM/AI coding agent package set (claude-code, opencode, codex, etc.)
    # Intentionally NOT following nixpkgs — derivation hashes must match
    # the garnix.io binary cache (cache.garnix.io) to avoid local compilation.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Beads task-graph tracker (br CLI)
    beads-rust = {
      url = "github:Dicklesworthstone/beads_rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Git worktree manager for parallel agent branches
    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    # ── Experimental agent tools ──────────────────────────────────────────────
    # Newer or less-proven tools; interface may change between releases.

    # Local document search (agents read docs/ before proposing changes)
    qmd = {
      url = "github:tobi/qmd";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    # Headless browser for QA/testing agents
    nix-lightpanda = {
      url = "github:deepwatrcreatur/nix-lightpanda";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Universal document-to-markdown converter
    nix-markit = {
      url = "github:deepwatrcreatur/nix-markit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Agent status system tray (Home Manager module)
    agents-status-tray-hm = {
      url = "github:deepwatrcreatur/agents-status-tray-home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      home-manager,
      fnox,
      nix-rtk,
      llm-agents,
      beads-rust,
      worktrunk,
      qmd,
      nix-lightpanda,
      nix-markit,
      agents-status-tray-hm,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # ── Overlays ─────────────────────────────────────────────────────────────

      # Single overlay combining all stable + experimental agent tools.
      # Consumers: inputs.nix-agent-fleet.overlays.default
      overlays.default =
        nixpkgs.lib.composeManyExtensions [
          llm-agents.overlays.default

          # fnox (prefer nixpkgs version on linux-x64 for binary cache hits)
          (final: prev: {
            fnox =
              if prev.stdenv.isLinux && prev.stdenv.isx86_64 then
                (prev.fnox or fnox.packages.${prev.stdenv.hostPlatform.system}.default)
              else
                fnox.packages.${prev.stdenv.hostPlatform.system}.default;
          })

          # Convenience aliases for packages from external flake outputs
          (final: prev: {
            beads-rust = beads-rust.packages.${prev.stdenv.hostPlatform.system}.default;
            worktrunk = worktrunk.packages.${prev.stdenv.hostPlatform.system}.default;
            qmd = qmd.packages.${prev.stdenv.hostPlatform.system}.default;
          })

          nix-lightpanda.overlays.default
          nix-markit.overlays.default
        ];

      # ── Home Manager modules ──────────────────────────────────────────────

      homeManagerModules = {
        default = self.homeManagerModules.agent-stack;

        # Full agent stack: RTK hooks + beads + LLM agents + status tray
        agent-stack =
          { ... }:
          {
            imports = [
              nix-rtk.homeManagerModules.default
              agents-status-tray-hm.homeManagerModules.default
              self.homeManagerModules.agent-packages
            ];

            # Enable RTK hooks with Claude by default; other integrations
            # must be opted in per-host.
            programs.rtk-hooks = {
              enable = nixpkgs.lib.mkDefault true;
              integrations.claude.enable = nixpkgs.lib.mkDefault true;
            };
          };

        # Packages only (no hooks or modules — useful for minimal setups)
        agent-packages =
          { pkgs, lib, ... }:
          {
            home.packages = with pkgs; [
              # Stable tools
              beads-rust
              worktrunk

              # Experimental tools
              qmd
            ] ++ lib.optionals pkgs.stdenv.isLinux [
              # linux-only for now
            ];
          };
      };

      # ── Package sets ──────────────────────────────────────────────────────

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          # Convenience bundle: nix run .#agent-bundle to get all tools on PATH
          agent-bundle = pkgs.buildEnv {
            name = "agent-bundle";
            paths = [
              beads-rust.packages.${system}.default
              worktrunk.packages.${system}.default
              qmd.packages.${system}.default
            ];
          };
        }
      );

      # ── Lib ──────────────────────────────────────────────────────────────

      lib = {
        # Promotion helper: lists tools by tier.
        # Useful for agents deciding which tools to trust for critical paths.
        toolTiers = {
          stable = [
            "fnox"
            "nix-rtk"
            "llm-agents"
            "beads-rust"
            "worktrunk"
          ];
          experimental = [
            "qmd"
            "nix-lightpanda"
            "nix-markit"
            "agents-status-tray-hm"
          ];
        };
      };
    };
}
