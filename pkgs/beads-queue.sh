#!/usr/bin/env bash
# beads-q: run beads-rust against a repo's shared queue branch.
#
# The queue lives on an orphan branch (default `beads-queue`) holding only .beads/.
# Each machine keeps one detached worktree of it per repo
# (~/flakes-worktrees/<repo>/beads). Every call:
#   1. fetches the branch and hard-resets the queue worktree to the remote tip
#      (it holds nothing but the queue, so nothing local is lost),
#   2. rebuilds the disposable SQLite cache from issues.jsonl,
#   3. runs the beads-rust command,
#   4. for write commands: exports, commits and pushes; if the push is
#      rejected (another agent pushed first), starts again from step 1, so a
#      duplicate claim fails with CLAIM_CONFLICT instead of a merge.
#
# Usage: beads-q [-C <dir in repo>] <beads-rust args...>
# Env:   BEADS_Q_BRANCH (beads-queue), BEADS_Q_REMOTE (origin), BEADS_Q_DIR,
#        BEADS_Q_RETRIES (5)
# Docs:  https://github.com/deepwatrcreatur/nix-agent-guides/blob/main/guides/beads.md
set -euo pipefail

repo_dir=$PWD
if [ "${1:-}" = "-C" ]; then
  repo_dir=$2
  shift 2
fi
if [ "$#" -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  cat <<'USAGE'
beads-q: run beads-rust against a repo's shared queue branch.

Usage: beads-q [-C <dir in repo>] <beads-rust args...>
  beads-q ready --json
  beads-q update <id> --claim --actor <you>
  beads-q close <id> --reason "<what, PR link>" --actor <you>

Each call fetches the queue branch, resets this machine's queue worktree
(~/flakes-worktrees/<repo>/beads) to the remote tip, rebuilds the cache and
runs the command. Write commands are committed and pushed; a rejected push is
retried on the new tip, so a duplicate claim fails with CLAIM_CONFLICT.

Env: BEADS_Q_BRANCH (beads-queue), BEADS_Q_REMOTE (origin), BEADS_Q_DIR,
     BEADS_Q_RETRIES (5)
USAGE
  exit 0
fi

branch=${BEADS_Q_BRANCH:-beads-queue}
remote=${BEADS_Q_REMOTE:-origin}
retries=${BEADS_Q_RETRIES:-5}

common=$(git -C "$repo_dir" rev-parse --path-format=absolute --git-common-dir)
# WHY: bare repos (~/flakes/<repo>) have no .git component; normal clones do.
if [ "$(basename "$common")" = ".git" ]; then
  name=$(basename "$(dirname "$common")")
else
  name=$(basename "$common" .git)
fi
qdir=${BEADS_Q_DIR:-$HOME/flakes-worktrees/$name/beads}
export BEADS_DIR=$qdir/.beads

# INVARIANT: one beads-q at a time per repo on this machine; the queue
# worktree and its cache are shared by every local agent.
exec 9>"$common/beads-q.lock"
flock 9

fetch() {
  git -C "$common" fetch -q "$remote" "+refs/heads/$branch:refs/remotes/$remote/$branch"
}

sync_from_remote() {
  fetch
  if [ ! -e "$qdir/.git" ]; then
    mkdir -p "$(dirname "$qdir")"
    git -C "$common" worktree add -q --detach "$qdir" "$remote/$branch"
  fi
  git -C "$qdir" reset -q --hard "$remote/$branch"
  rm -f "$BEADS_DIR"/beads.db "$BEADS_DIR"/beads.db-wal "$BEADS_DIR"/beads.db-shm
  beads-rust sync --import-only >/dev/null
}

# WHY: only write commands export and push; exporting after a read could
# rewrite the file with formatting churn and create empty-meaning commits.
case "$1" in
  ready | list | show | search | stats | status | blocked | count | graph | \
  info | where | version | doctor | config | dep-tree | --version | -V)
    sync_from_remote
    exec beads-rust "$@"
    ;;
  dep)
    case "${2:-}" in list | tree | cycles) sync_from_remote; exec beads-rust "$@" ;; esac
    ;;
  comments)
    case "${2:-}" in list | "") sync_from_remote; exec beads-rust "$@" ;; esac
    ;;
esac

attempt=1
while :; do
  sync_from_remote
  set +e
  beads-rust "$@"
  status=$?
  set -e
  [ "$status" -eq 0 ] || exit "$status"

  beads-rust sync --flush-only >/dev/null
  if git -C "$qdir" diff --quiet -- .beads/issues.jsonl; then
    exit 0
  fi
  git -C "$qdir" add -- .beads/issues.jsonl
  git -C "$qdir" commit -q -m "beads: $(printf '%s ' "$@" | cut -c1-200)"
  if git -C "$qdir" push -q "$remote" "HEAD:refs/heads/$branch" 2>/dev/null; then
    exit 0
  fi
  if [ "$attempt" -ge "$retries" ]; then
    echo "beads-q: push to $remote/$branch rejected $attempt times; giving up" >&2
    exit 1
  fi
  echo "beads-q: $remote/$branch moved; retrying on the new tip ($attempt/$retries)" >&2
  attempt=$((attempt + 1))
done
