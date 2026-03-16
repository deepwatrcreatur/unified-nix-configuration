{ prev }:
prev.stdenvNoCC.mkDerivation {
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
}
