{ pkgs, lib }:

pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "dmux";
  version = "5.6.3";

  src = pkgs.fetchFromGitHub {
    owner = "standardagents";
    repo = "dmux";
    rev = "v${finalAttrs.version}";
    hash = "sha256-pyeZlJsDKWR6eCagnHDi1Ktl/iPvMjbxkg3xiFmCCXc=";
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-Kd50v58VLHVb4h4TZqtNGMRb+xuPmbsFSHHGpm0QPOQ=";
  };

  nativeBuildInputs = [
    pkgs.nodejs
    pkgs.pnpmConfigHook
    pkgs.pnpm_10
    pkgs.gnused
  ];

  dontNpmBuild = true;

  buildPhase = ''
    runHook preBuild

    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib/${finalAttrs.pname}

    cp -r ./dist $out/lib/${finalAttrs.pname}
    cp -r ./node_modules $out/lib/${finalAttrs.pname}/node_modules
    cp -r ./frontend $out/lib/${finalAttrs.pname}/frontend
    cp -r ./docs $out/lib/${finalAttrs.pname}/docs
    cp ./package.json $out/lib/${finalAttrs.pname}/package.json

    sed -i "s|\.\/dist\/index\.js|$out/lib/${finalAttrs.pname}/dist/index.js|" ./dmux
    sed -i "s|\.\.\/dist\/index\.js|$out/lib/${finalAttrs.pname}/dist/index.js|" ./dmux

    cp ./dmux $out/bin/dmux-upstream
    chmod +x $out/bin/dmux-upstream

    cat > $out/bin/dmux <<'EOF'
#!${pkgs.bash}/bin/bash
set -euo pipefail

real_dmux="@real_dmux@"
git_bin="${pkgs.git}/bin/git"
allow_shared="''${DMUX_ALLOW_SHARED_CHECKOUT:-0}"
mode="run"
args=()

print_shared_checkout_guidance() {
  local repo_root="$1"
  local repo_name parent_dir example_path
  repo_name="$(basename "$repo_root")"
  parent_dir="$(dirname "$repo_root")"
  example_path="$parent_dir/''${repo_name}-worktree"

  cat >&2 <<GUIDANCE
dmux: refusing to launch from the primary checkout at:
  $repo_root

This first-slice guard keeps shared checkouts read-mostly for agent mutation.
Launch dmux from a linked git worktree instead, for example:

  git -C "$repo_root" worktree add "$example_path" -b <branch-name>
  cd "$example_path"
  dmux

To inspect the current decision without launching dmux:

  dmux preflight

To bypass this guard once, use an explicit override:

  DMUX_ALLOW_SHARED_CHECKOUT=1 dmux --allow-shared-checkout

Read-only inspection from the shared checkout remains allowed outside dmux.
GUIDANCE
}

if [ "''${1:-}" = "preflight" ]; then
  mode="preflight"
  shift
fi

for arg in "$@"; do
  case "$arg" in
    --allow-shared-checkout)
      allow_shared=1
      ;;
    *)
      args+=("$arg")
      ;;
  esac
done

if [ "$mode" = "run" ]; then
  case "''${args[0]:-}" in
    -h|--help|help|--version|-v)
      exec "$real_dmux" "''${args[@]}"
      ;;
  esac
fi

if ! repo_root="$("$git_bin" rev-parse --show-toplevel 2>/dev/null)"; then
  if [ "$mode" = "preflight" ]; then
    echo "dmux preflight: not inside a git repository; no shared-checkout guard decision made."
    exit 0
  fi

  exec "$real_dmux" "''${args[@]}"
fi

if [ -f "$repo_root/.git" ]; then
  checkout_kind="linked-worktree"
elif [ -d "$repo_root/.git" ]; then
  checkout_kind="primary-checkout"
else
  checkout_kind="unknown"
fi

case "$mode:$checkout_kind:$allow_shared" in
  preflight:linked-worktree:*)
    echo "dmux preflight: allowed (linked git worktree detected at $repo_root)"
    exit 0
    ;;
  preflight:primary-checkout:1)
    echo "dmux preflight: allowed by explicit override from primary checkout at $repo_root"
    exit 0
    ;;
  preflight:primary-checkout:*)
    echo "dmux preflight: blocked (primary checkout detected at $repo_root)" >&2
    print_shared_checkout_guidance "$repo_root"
    exit 1
    ;;
  preflight:unknown:*)
    echo "dmux preflight: unable to classify checkout at $repo_root; allowing for now."
    exit 0
    ;;
  run:primary-checkout:1)
    ;;
  run:primary-checkout:*)
    print_shared_checkout_guidance "$repo_root"
    exit 1
    ;;
esac

exec "$real_dmux" "''${args[@]}"
EOF

    sed -i "s|@real_dmux@|$out/bin/dmux-upstream|" $out/bin/dmux

    chmod +x $out/bin/dmux
  '';

  meta = {
    description = "A development agent multiplexer for git";
    homepage = "https://github.com/standardagents/dmux";
    license = pkgs.lib.licenses.mit;
    mainProgram = "dmux";
  };
})
