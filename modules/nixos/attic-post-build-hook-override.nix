# Override attic post-build-hook to use attic-cache hostname instead of cache-build-server
{
  config,
  lib,
  pkgs,
  ...
}:

let
  atticUploadScript = pkgs.writeShellScript "attic-upload.sh" ''
    #!/usr/bin/env bash
    # Fail-safe post-build hook - never blocks builds.
    set -uo pipefail

    out_paths="''${OUT_PATHS-}"
    drv_path="''${DRV_PATH-}"

    if [ -z "$out_paths" ]; then
      exit 0
    fi

    # Skip source/temporary derivations.
    if [[ "$drv_path" == *"-source.drv" ]] || [[ "$drv_path" == *"tmp"* ]]; then
      exit 0
    fi

    token_file="/run/secrets/attic-client-token"
    if [ ! -f "$token_file" ]; then
      echo "Attic: Token not available, skipping push" >&2
      exit 0
    fi

    token=$(cat "$token_file" 2>/dev/null || true)
    if [ -z "$token" ]; then
      echo "Attic: Token empty, skipping push" >&2
      exit 0
    fi

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    export XDG_CONFIG_HOME="$tmpdir"
    mkdir -p "$XDG_CONFIG_HOME/attic"

    cat > "$XDG_CONFIG_HOME/attic/config.toml" <<EOF
    [servers.attic-cache]
    endpoint = "http://attic-cache:5001"
    token = "$token"
    EOF

    {
      echo "Attic: pushing to attic-cache:cache-local" >&2
      # shellcheck disable=SC2086
      ${pkgs.attic-client}/bin/attic push "attic-cache:cache-local" $out_paths 2>&1 || true
    } || true

    exit 0
  '';

  isCacheServer = config.networking.hostName or "" == "attic-cache";
in
{
  config = lib.mkIf (!isCacheServer) {
    nix.settings.post-build-hook = lib.mkForce "${atticUploadScript}";
  };
}
