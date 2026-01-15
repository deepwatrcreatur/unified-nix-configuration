# flake.nix
{
  description = "Multi-system Nix configurations (NixOS, nix-darwin, Home Manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    determinate.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.inputs.flake-utils.follows = "flake-utils";

    flake-utils.url = "github:numtide/flake-utils";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    tap-romkatv-powerlevel10k = {
      url = "github:romkatv/powerlevel10k";
      flake = false;
    };

    tap-gabe565 = {
      url = "github:gabe565/homebrew-tap";
      flake = false;
    };

    tap-sst = {
      url = "github:sst/homebrew-tap";
      flake = false;
    };

    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-snapd = {
      url = "github:nix-community/nix-snapd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-whitesur-config = {
      url = "github:deepwatrcreatur/nix-whitesur-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tesla-inference-flake = {
      url = "github:deepwatrcreatur/tesla-inference-flake"; # Use latest main with official binaries
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fnox = {
      url = "github:deepwatrcreatur/fnox-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = true;
    };

    zellij-vivid-rounded = {
      url = "github:deepwatrcreatur/nix-zellij-vivid-rounded";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gnome-cosmic-ui = {
      url = "github:deepwatrcreatur/nix-gnome-cosmic-ui";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    worktrunk = {
      url = "github:max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

  };

  outputs =
    inputs:
    let
      # Standard library from nixpkgs - this is the "pure" lib
      nixpkgsLib = inputs.nixpkgs.lib;

      commonNixpkgsConfig = {
        allowUnfree = true;
      };

      # Extract the opencode override overlay so we can exclude it from the
      # nested unstable import (prevents infinite recursion).
      opencodeFromUnstableOverlay =
        final: prev:
        let
          overlaysForUnstable = nixpkgsLib.filter (o: o != opencodeFromUnstableOverlay) commonOverlays;
          unstable = import inputs.nixpkgs-unstable {
            system = prev.stdenv.hostPlatform.system;
            config = commonNixpkgsConfig;
            overlays = overlaysForUnstable;
          };
        in
        {
          opencode = unstable.opencode or prev.opencode;
        };

      commonOverlays = [
        # Overlay to selectively use stable packages when unstable ones cause issues
        (
          final: prev:
          let
            stable = import inputs.nixpkgs-stable {
              system = prev.stdenv.hostPlatform.system;
              config = commonNixpkgsConfig;
            };
          in
          {
            # Add stable packages here when needed to avoid compilation
            # Example: some-package = stable.some-package;
          }
        )
        (final: prev: {
          inherit (inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}) tailscale;
        })
        # Grok CLI overlay
        (final: prev: {
          fish = prev.fish.overrideAttrs (oldAttrs: {
            doCheck = false;
          });
        })

        # Prefer opencode from nixpkgs-unstable
        opencodeFromUnstableOverlay

        # Worktrunk (git worktree management for parallel agents)
        (final: prev: {
          worktrunk = inputs.worktrunk.packages.${prev.stdenv.hostPlatform.system}.default;
        })

        # ProxMenux (Proxmox VE interactive menu)
        (final: prev: {
          proxmenux = prev.stdenvNoCC.mkDerivation {
            pname = "proxmenux";
            version = "1.1.8";
            src = prev.fetchFromGitHub {
              owner = "MacRimi";
              repo = "ProxMenux";
              rev = "v1.1.8";
              hash = "sha256-keeLFu594/Qg/HfbNayiMzvI7XgjoMr4D1QHMUdMJEc=";
            };

            dontBuild = true;

            installPhase = ''
              runHook preInstall

              mkdir -p "$out/share/proxmenux" "$out/bin"

              cp -r scripts "$out/share/proxmenux/scripts"
              install -m644 version.txt "$out/share/proxmenux/version.txt"
              install -m644 scripts/utils.sh "$out/share/proxmenux/utils.sh"

              if [ -f json/cache.json ]; then
                install -m644 json/cache.json "$out/share/proxmenux/default-cache.json"
              else
                echo '{}' > "$out/share/proxmenux/default-cache.json"
              fi

              cat > "$out/share/proxmenux/menu" <<'EOF'
              #!${prev.bash}/bin/bash
              set -euo pipefail

              DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
              BASE_DIR="''${PROXMENUX_BASE_DIR:-$DATA_HOME/proxmenux}"
              LOCAL_SCRIPTS="$BASE_DIR/scripts"
              CONFIG_FILE="$BASE_DIR/config.json"
              CACHE_FILE="$BASE_DIR/cache.json"
              UTILS_FILE="$BASE_DIR/utils.sh"
              LOCAL_VERSION_FILE="$BASE_DIR/version.txt"

              if [[ -f "$UTILS_FILE" ]]; then
                source "$UTILS_FILE"
              else
                echo "ProxMenux not initialized (missing $UTILS_FILE)" >&2
                exit 1
              fi

              main_menu() {
                local MAIN_MENU="$LOCAL_SCRIPTS/menus/main_menu.sh"
                exec bash "$MAIN_MENU"
              }

              load_language
              initialize_cache
              main_menu
              EOF
              chmod +x "$out/share/proxmenux/menu"

              cat > "$out/bin/menu" <<'EOF'
              #!${prev.bash}/bin/bash
              set -euo pipefail

              SELF="${prev.coreutils}/bin/readlink"
              DIRNAME="${prev.coreutils}/bin/dirname"
              MKDIR="${prev.coreutils}/bin/mkdir"
              CP="${prev.coreutils}/bin/cp"
              TEST="${prev.coreutils}/bin/test"

              self_path="$($SELF -f "$0")"
              bin_dir="$($DIRNAME "$self_path")"
              prefix="$($DIRNAME "$bin_dir")"
              seed_dir="$prefix/share/proxmenux"

              data_home="''${XDG_DATA_HOME:-$HOME/.local/share}"
              state_dir="$data_home/proxmenux"

              export PATH="${
                prev.lib.makeBinPath [
                  prev.bash
                  prev.coreutils
                  prev.curl
                  prev.wget
                  prev.jq
                  prev.newt
                  prev.git
                  prev.iproute2
                ]
              }:$PATH"

              $MKDIR -p "$state_dir"

              # Initialize or update seeded files (but never overwrite config).
              if ! $TEST -e "$state_dir/scripts/menus/main_menu.sh"; then
                $CP -r "$seed_dir/scripts" "$state_dir/scripts"
              fi
              if ! $TEST -e "$state_dir/utils.sh"; then
                $CP "$seed_dir/utils.sh" "$state_dir/utils.sh"
              fi
              if ! $TEST -e "$state_dir/version.txt"; then
                $CP "$seed_dir/version.txt" "$state_dir/version.txt"
              fi
              if ! $TEST -e "$state_dir/cache.json"; then
                $CP "$seed_dir/default-cache.json" "$state_dir/cache.json"
              fi
              if ! $TEST -e "$state_dir/config.json"; then
                echo '{"language":"en"}' > "$state_dir/config.json"
              fi

              export PROXMENUX_BASE_DIR="$state_dir"
              exec bash "$seed_dir/menu" "$@"
              EOF
              chmod +x "$out/bin/menu"

              runHook postInstall
            '';

            meta = {
              description = "ProxMenux interactive menu for Proxmox VE";
              homepage = "https://github.com/MacRimi/ProxMenux";
              mainProgram = "menu";
              platforms = [
                "x86_64-linux"
                "aarch64-linux"
              ];
            };
          };
        })

        # Factory.ai Droid CLI (prebuilt binary, patched on NixOS)
        #
        # Factory publishes both "x64" and "x64-baseline" for Linux. The baseline
        # artifact currently appears to be Bun itself, while the "x64" artifact is
        # the actual droid CLI. The official installer selects based on AVX2.
        (
          final: prev:
          let
            version = "0.48.1";
            system = prev.stdenv.hostPlatform.system;
            platform = if prev.stdenv.isDarwin then "darwin" else "linux";
            isX86_64Linux = system == "x86_64-linux";

            hashBySystem = {
              "aarch64-linux" = "sha256-ZujFPpKUASj1xA/gNYxE2brw5ebAGtmyfB9M3mMc24k=";
              "x86_64-darwin" = "sha256-qCt8fS8/IYm53UhOtDF6u831NzgSVbVdYUr7uToEGFE=";
              "aarch64-darwin" = "sha256-M0QYX7u9GHqHcPbL9dR7+vC2QIUxrgN4N2cSAIAmmRE=";
            };

            # Working CLI on modern x86_64 Linux
            srcX64Linux = prev.fetchurl {
              url = "https://downloads.factory.ai/factory-cli/releases/${version}/linux/x64/droid";
              hash = "sha256-gOGbOy9YQibgN8nJRDmOvNs8tVNpgKj86ckzTbGzZ2U=";
            };

            # Kept for completeness / older CPUs (selected at runtime)
            srcX64BaselineLinux = prev.fetchurl {
              url = "https://downloads.factory.ai/factory-cli/releases/${version}/linux/x64-baseline/droid";
              hash = "sha256-5QsvAvmcjVbplJB0JHhqfSKJtoCTAuVXXgj5cu57Q6M=";
            };

            archGeneric = if prev.stdenv.hostPlatform.isAarch64 then "arm64" else "x64-baseline";
            srcGeneric = prev.fetchurl {
              url = "https://downloads.factory.ai/factory-cli/releases/${version}/${platform}/${archGeneric}/droid";
              hash = hashBySystem.${system};
            };
          in
          {
            factory-droid =
              if isX86_64Linux then
                let
                  # The x64 droid binary behaves correctly when executed in an
                  # FHS-ish runtime environment (as in the official installer).
                  droidUnwrapped = prev.stdenvNoCC.mkDerivation {
                    pname = "factory-droid-unwrapped";
                    src = srcX64Linux;
                    inherit version;
                    dontUnpack = true;

                    installPhase = ''
                      runHook preInstall
                      mkdir -p "$out/bin"
                      install -m755 "$src" "$out/bin/droid"
                      runHook postInstall
                    '';
                  };
                in
                prev.buildFHSEnv {
                  name = "droid";
                  runScript = "${droidUnwrapped}/bin/droid";
                  targetPkgs =
                    pkgs:
                    with pkgs;
                    [
                      git
                      openssh
                      ripgrep
                    ]
                    ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ xdg-utils ];
                  meta = {
                    description = "Factory.ai Droid CLI";
                    homepage = "https://factory.ai";
                    mainProgram = "droid";
                    platforms = [ "x86_64-linux" ];
                  };
                }
              else
                prev.stdenv.mkDerivation {
                  pname = "factory-droid";
                  src = srcGeneric;
                  inherit version;
                  dontUnpack = true;

                  nativeBuildInputs = [
                    prev.makeWrapper
                  ]
                  ++ nixpkgsLib.optionals prev.stdenv.isLinux [
                    prev.autoPatchelfHook
                    prev.patchelf
                  ];
                  buildInputs = nixpkgsLib.optionals prev.stdenv.isLinux [
                    prev.stdenv.cc.cc.lib
                    prev.glibc
                  ];

                  installPhase = ''
                    runHook preInstall
                    mkdir -p "$out/bin"
                    install -m755 "$src" "$out/bin/droid"

                    if [ "${if prev.stdenv.isLinux then "1" else "0"}" = "1" ]; then
                      patchelf --set-interpreter "$(cat ${prev.stdenv.cc}/nix-support/dynamic-linker)" "$out/bin/droid"
                      autoPatchelf "$out/bin/droid" || true
                    fi

                    wrapProgram "$out/bin/droid" \
                      --prefix PATH : "${
                        prev.lib.makeBinPath (
                          [
                            prev.ripgrep
                            prev.git
                            prev.openssh
                          ]
                          ++ prev.lib.optionals prev.stdenv.isLinux [ prev.xdg-utils ]
                        )
                      }"

                    runHook postInstall
                  '';

                  meta = {
                    description = "Factory.ai Droid CLI";
                    homepage = "https://factory.ai";
                    mainProgram = "droid";
                    platforms = [
                      "aarch64-linux"
                      "x86_64-darwin"
                      "aarch64-darwin"
                    ];
                  };
                };
          }
        )

        # Provide fnox + related wrappers (prefer flake input)
        (
          final: prev:
          let
            system = prev.stdenv.hostPlatform.system;
            flakeHasPkgs = builtins.hasAttr system inputs.fnox.packages;
            fnoxPkgs = if flakeHasPkgs then inputs.fnox.packages.${system} else { };
            flakeHasFnox = fnoxPkgs ? default;
          in
          (
            if flakeHasFnox then
              { fnox = fnoxPkgs.default; }
            else if prev ? fnox then
              { fnox = prev.fnox; }
            else
              { }
          )
          // (nixpkgsLib.optionalAttrs (fnoxPkgs ? gh-fnox) { gh-fnox = fnoxPkgs.gh-fnox; })
          // (nixpkgsLib.optionalAttrs (fnoxPkgs ? bw-fnox) { bw-fnox = fnoxPkgs.bw-fnox; })
        )

        # Opencode wrappers must use our (unstable) opencode, not the fnox-flake baked one.
        (
          final: prev:
          let
            mkWrapped =
              {
                name,
                providerEnv,
                secretName,
                keyEnv ? "OPENAI_API_KEY",
              }:
              prev.writeShellScriptBin name ''
                set -euo pipefail

                FNOX_CONFIG_PATH="''${FNOX_CONFIG:-$HOME/.config/fnox/config.toml}"
                export FNOX_AGE_KEY_FILE="''${FNOX_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

                value=$("${final.fnox}/bin/fnox" -c "$FNOX_CONFIG_PATH" get "${secretName}")
                export ${keyEnv}="$value"

                ${providerEnv}

                exec "${final.opencode}/bin/opencode" "$@"
              '';
          in
          {
            opencode-zai = mkWrapped {
              name = "opencode-zai";
              secretName = "Z_AI_API_KEY";
              providerEnv = ''
                export OPENCODE_PROVIDER="z.ai"
                export OPENCODE_MODEL="GLM 4.7"
              '';
            };

            opencode-claude = mkWrapped {
              name = "opencode-claude";
              secretName = "ANTHROPIC_API_KEY";
              keyEnv = "ANTHROPIC_API_KEY";
              providerEnv = "";
            };
          }
        )

        # Tesla inference overlays for GPU optimization
        inputs.tesla-inference-flake.overlays.ollama-official-binaries # Use official binaries to avoid cuda_compat build error
        inputs.tesla-inference-flake.overlays.llama-cpp-tesla
        inputs.tesla-inference-flake.overlays.gpu-tools
        # Try to use fnox from nixpkgs first, fallback to flake input if not available
        # (final: prev: {
        #   fnox =
        #     if prev.stdenv.isLinux && prev.stdenv.isx86_64 then
        #       # Try to get fnox from nixpkgs (should be pre-built in newer versions)
        #       (prev.fnox or inputs.fnox.packages.${prev.stdenv.hostPlatform.system}.default)
        #     else
        #       # Fallback to flake input for other platforms
        #       inputs.fnox.packages.${prev.stdenv.hostPlatform.system}.default;
        # })
      ];

      # SpecialArgs for NixOS and Darwin SYSTEM modules.
      # These modules can safely receive the pure nixpkgsLib.
      systemSpecialArgs = {
        inherit inputs;
        lib = nixpkgsLib;
        myModules = import ./modules;
      };

      # SpecialArgs specifically for HOME MANAGER modules.
      # We only pass 'inputs'. Home Manager will provide its own 'lib' and 'config.lib'.
      homeManagerModuleArgs = {
        inherit inputs;
        inherit (inputs) mac-app-util;
      };

      # Helper to import all .nix files from a directory as module paths
      importAllModulesInDir =
        dir:
        let
          items = builtins.readDir dir;
          isNixFile =
            name: type: type == "regular" && nixpkgsLib.hasSuffix ".nix" name && !nixpkgsLib.hasPrefix "_" name;
          nixFileNames = nixpkgsLib.attrNames (nixpkgsLib.filterAttrs isNixFile items);
        in
        map (fileName: dir + "/${fileName}") nixFileNames;

      # Helper to auto-import all .nix files and directories from a common directory
      # Used by module default.nix files to automatically load all modules from a common subdirectory
      autoImportCommon =
        {
          commonDir,
          lib,
          includeDirectories ? true,
          excludeFiles ? [ ],
        }:
        let
          items = builtins.readDir commonDir;
          # Filter to include .nix files and optionally directories
          isValidItem =
            name: type:
            (type == "regular" && nixpkgsLib.hasSuffix ".nix" name && !nixpkgsLib.elem name excludeFiles)
            || (includeDirectories && type == "directory");
          validItems = nixpkgsLib.filterAttrs isValidItem items;
        in
        nixpkgsLib.mapAttrsToList (name: _: commonDir + "/${name}") validItems;

      # Helper to create platform-specific modules with base + platform-specific extensions
      # Usage: mkPlatformModule { base = "..."; darwin = "..."; nixos = "..."; }
      mkPlatformModule =
        pkgs:
        {
          base ? "",
          darwin ? "",
          nixos ? "",
        }:
        base
        + (
          if pkgs.stdenv.isDarwin then
            darwin
          else if pkgs.stdenv.isLinux then
            nixos
          else
            ""
        );

      # Common module configurations shared across all system builders
      commonSystemModules = [
        {
          nixpkgs.overlays = commonOverlays;
          nixpkgs.config = commonNixpkgsConfig;
        }
      ];

      # Home Manager configuration for NixOS systems (used by mkNixosSystem)
      nixosHomeManagerConfig =
        { hostName, isDesktop }:
        {
          home-manager.extraSpecialArgs = homeManagerModuleArgs // {
            inherit hostName isDesktop;
          };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        };

      # Home Manager configuration for Omarchy systems (minimal variant)
      omarchyHomeManagerConfig = {
        home-manager.extraSpecialArgs = homeManagerModuleArgs;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      };

      # Helper functions to reduce boilerplate in individual host files
      helpers = {
        # Standard NixOS system builder
        mkNixosSystem =
          {
            system ? "x86_64-linux",
            hostPath,
            modules ? [ ],
            extraModules ? [ ],
            isDesktop ? false,
            includeSnapd ? true,
          }:
          let
            hostName = builtins.baseNameOf (toString hostPath);
            baseModules = commonSystemModules ++ [
              inputs.sops-nix.nixosModules.sops
              inputs.home-manager.nixosModules.home-manager
              (nixosHomeManagerConfig { inherit hostName isDesktop; })
              # inputs.determinate.nixosModules.default # TEMPORARILY DISABLED
              inputs.tesla-inference-flake.nixosModules.tesla-inference
            ];
            snapdModules = nixpkgsLib.optionals includeSnapd [
              inputs.nix-snapd.nixosModules.default
            ];
          in
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = systemSpecialArgs;
            modules =
              baseModules
              ++ snapdModules
              ++ [
                ./modules
                hostPath
              ]
              ++ modules
              ++ extraModules;
          };

        # Standard Darwin system builder
        mkDarwinSystem =
          {
            system ? "aarch64-darwin",
            hostPath,
            username,
            modules ? [ ],
            isDesktop ? true,
          }:
          let
            hostName = builtins.baseNameOf (toString hostPath);
          in
          inputs.nix-darwin.lib.darwinSystem {
            inherit system;
            specialArgs = systemSpecialArgs // {
              inherit (inputs) nix-homebrew;
            };
            modules =
              commonSystemModules
              ++ [
                ./modules
                hostPath
                inputs.home-manager.darwinModules.home-manager
                (
                  { pkgs, ... }:
                  {
                    home-manager.users.${username} = {
                      imports = [
                        ./users/${username}
                        ./users/${username}/hosts/${hostName}
                        ./modules/home-manager
                      ];
                    };
                    home-manager.extraSpecialArgs = homeManagerModuleArgs // {
                      inherit hostName isDesktop;
                    };
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                  }
                )
                (
                  { pkgs, ... }:
                  {
                    users.users.${username} = {
                      name = username;
                      home = "/Users/${username}";
                      shell = pkgs.fish;
                    };
                  }
                )
              ]
              ++ modules;
          };

        mkOmarchySystem =
          {
            system ? "x86_64-linux",
            hostPath,
            modules ? [ ],
            extraModules ? [ ],
          }:
          let
            hostName = builtins.baseNameOf (toString hostPath);
          in
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = systemSpecialArgs;
            modules =
              commonSystemModules
              ++ [
                inputs.sops-nix.nixosModules.sops
                inputs.home-manager.nixosModules.home-manager
                inputs.determinate.nixosModules.default
                omarchyHomeManagerConfig
                ./modules
                hostPath
              ]
              ++ modules
              ++ extraModules;
          };

        # Standard Home Manager configuration builder
        mkHomeConfig =
          {
            system ? "x86_64-linux",
            userPath,
            modules ? [ ],
            isDesktop ? false,
          }:
          inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import inputs.nixpkgs {
              system = system;
              config = commonNixpkgsConfig;
              overlays = commonOverlays;
            };
            extraSpecialArgs = homeManagerModuleArgs // {
              inherit isDesktop;
              hostName = "";
            };
            modules = [
              userPath
              ./modules/home-manager
              inputs.sops-nix.homeManagerModules.sops
            ]
            ++ modules;
          };

        # Output builder for single NixOS configuration
        mkNixosOutput =
          {
            name,
            system ? "x86_64-linux",
            hostPath,
            modules ? [ ],
            extraModules ? [ ],
            isDesktop ? false,
            includeSnapd ? true,
          }:
          nixpkgsLib.setAttrByPath [ "nixosConfigurations" name ] (
            helpers.mkNixosSystem {
              inherit
                system
                hostPath
                modules
                extraModules
                isDesktop
                includeSnapd
                ;
            }
          );

        # Output builder for single Darwin configuration
        mkDarwinOutput =
          {
            name,
            system ? "aarch64-darwin",
            hostPath,
            username,
            modules ? [ ],
            isDesktop ? true,
          }:
          nixpkgsLib.setAttrByPath [ "darwinConfigurations" name ] (
            helpers.mkDarwinSystem {
              inherit
                system
                hostPath
                username
                modules
                isDesktop
                ;
            }
          );

        # Merge multiple output configurations (used for files with multiple hosts)
        # Use recursiveUpdate to properly merge nested nixosConfigurations
        mergeOutputs =
          outputs: nixpkgsLib.foldl' (acc: out: nixpkgsLib.recursiveUpdate acc out) { } outputs;
      };

      # Helper to load and merge all output configurations
      loadOutputs =
        outputsDir:
        let
          outputFiles = importAllModulesInDir outputsDir;
          # Create a context object that output files can use
          outputContext = {
            inherit
              inputs
              nixpkgsLib
              commonNixpkgsConfig
              commonOverlays
              systemSpecialArgs
              homeManagerModuleArgs
              importAllModulesInDir
              helpers
              ;
          };
        in
        nixpkgsLib.foldl' (
          acc: file: nixpkgsLib.recursiveUpdate acc (import file outputContext)
        ) { } outputFiles;

    in
    (loadOutputs ./outputs)
    // {
      hm-opts = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
        };
        modules = [ ./modules/home-manager/non-nixos.nix ];
      };
    };
}
