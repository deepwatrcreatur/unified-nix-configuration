# overlays/packages.nix
# Custom packages defined in pkgs/
{ nixpkgsLib }:

[
  # ProxMenux (Proxmox VE interactive menu)
  (final: prev: {
    proxmenux = prev.callPackage ../pkgs/proxmenux.nix { };
  })

  # iVentoy Free Edition (PXE ISO menu server)
  (import ./iventoy.nix)

  # Factory.ai Droid CLI
  (final: prev: {
    factory-droid = prev.callPackage ../pkgs/factory-droid.nix { };
  })

  # T3Code (AI code editor)
  (final: prev: {
    t3code = prev.callPackage ../pkgs/t3code.nix { };
  })

  # Wrapped GitHub CLI using fnox-backed token lookup
  (final: prev: {
    gh-fnox = final.callPackage ../pkgs/gh-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped Bitwarden CLI using fnox-backed session lookup
  (final: prev: {
    bw-fnox = final.callPackage ../pkgs/bw-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped Attic CLI with fnox-backed login token lookup
  (final: prev: {
    attic-fnox = final.callPackage ../pkgs/attic-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped Proxmox Backup Client with fnox-backed password lookup
  (final: prev: {
    proxmox-backup-client-fnox = final.callPackage ../pkgs/proxmox-backup-client-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped Factory.ai Droid CLI with fnox-backed API key lookup
  (final: prev: {
    factory-droid-fnox = final.callPackage ../pkgs/factory-droid-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped Claude Code CLI with fnox-backed API key lookup
  (final: prev: {
    claude-code-fnox = final.callPackage ../pkgs/claude-code-fnox.nix {
      fnox = final.fnox;
    };
  })

  # Wrapped OpenCode CLI with fnox-backed Z_AI_API_KEY lookup.
  # Uses pkgs.llm-agents.opencode (the repo-managed version) instead of the
  # fnox-flake's own bundled opencode, which lags behind the overlay version.
  (final: prev: {
    opencode-zai = final.callPackage ../pkgs/opencode-zai.nix {
      opencode = final.llm-agents.opencode;
      fnox = final.fnox;
    };
  })

  # repo_updater (ru) — parallelized multi-repo sync and review CLI
  (final: prev: {
    repo-updater = prev.callPackage ../pkgs/repo-updater.nix { };
  })

  # beads_viewer (bv) — terminal UI and robot-triage engine for the Beads store
  (final: prev: {
    beads-viewer = prev.callPackage ../pkgs/beads-viewer.nix { };
  })

  # Repo-managed beads_rust package from release binaries.
  # The upstream flake package is currently not reproducible here, so use the
  # published release tarballs instead and keep the user-facing wrapper command
  # as `beads-rust` to avoid colliding with the Homebrew beads_viewer `br`
  # command.
  (final: prev: {
    beads-rust =
      let
        version = "0.1.45";
        target =
          {
            x86_64-linux = {
              asset = "br-v${version}-linux_musl_amd64.tar.gz";
              hash = "sha256-3r7Z2y8bPedyfB5OwduX3Rna5dMFhLIo0+VaHKcdmeE=";
            };
            aarch64-linux = {
              asset = "br-v${version}-linux_arm64.tar.gz";
              hash = "";
            };
            x86_64-darwin = {
              asset = "br-v${version}-darwin_amd64.tar.gz";
              hash = "";
            };
            aarch64-darwin = {
              asset = "br-v${version}-darwin_arm64.tar.gz";
              hash = "";
            };
          }
          .${prev.stdenv.hostPlatform.system}
          or (throw "Unsupported system for beads-rust: ${prev.stdenv.hostPlatform.system}");
      in
      prev.stdenvNoCC.mkDerivation {
        pname = "beads-rust";
        inherit version;

        src = prev.fetchurl {
          url = "https://github.com/Dicklesworthstone/beads_rust/releases/download/v${version}/${target.asset}";
          inherit (target) hash;
        };

        dontUnpack = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          tar -xzf "$src" -C $TMPDIR
          install -m755 "$TMPDIR/br" "$out/bin/br"
          runHook postInstall
        '';

        meta = with prev.lib; {
          description = "Agent-first issue tracker (SQLite + JSONL)";
          homepage = "https://github.com/Dicklesworthstone/beads_rust";
          license = licenses.mit;
          mainProgram = "br";
          platforms = builtins.attrNames {
            x86_64-linux = true;
            aarch64-linux = true;
            x86_64-darwin = true;
            aarch64-darwin = true;
          };
        };
      };
  })

  # Expose the CLI as `beads-rust` so it does not collide with the Homebrew
  # beads_viewer `br` command.
  (final: prev: {
    beads-rust-cli = prev.writeShellApplication {
      name = "beads-rust";
      runtimeInputs = [ final.beads-rust ];
      text = ''
        exec ${final.beads-rust}/bin/br "$@"
      '';
    };
  })

  # mem0ai — semantic long-term memory layer for AI agents
  (final: prev: {
    mem0ai = prev.callPackage ../pkgs/mem0ai.nix {
      python3Packages = prev.python3Packages;
    };
    # Convenience: Python env with mem0 pre-loaded alongside key CLI tools
    mem0-env = prev.python3.withPackages (
      ps:
      [
        (prev.callPackage ../pkgs/mem0ai.nix { python3Packages = ps; })
      ]
    );
  })
]
