# Persistent Sessions for Long-Running Work

Use a persistent session when a command must outlive your SSH connection or
your agent turn (long builds, servers, monitoring).

## Developer hosts: herdr

`herdr` is the repo-managed agent workspace manager on hosts with
`programs.herdr.enable` (the developer aspect: emerald, phoenix, attic-cache).
Use its sessions, workspaces and worktrees rather than raw tmux:

```bash
herdr --session build-debug          # create or attach a named session
herdr session list                    # list, attach or stop named sessions
herdr session attach build-debug
herdr --remote attic-cache           # work in a herdr session on another host
herdr worktree --help                # worktree-backed workspaces
```

State layout, worktree model and safety rules:
[docs/herdr-state-and-worktree-model.md](../docs/herdr-state-and-worktree-model.md).

## Servers without herdr: tmux

Router and homeserver do not have herdr; tmux is installed everywhere.

```bash
ssh host "tmux new-session -d -s build-debug"
ssh host "tmux send-keys -t build-debug 'nix build .#foo 2>&1 | tee /tmp/build.log' Enter"
ssh host "tmux list-sessions"
ssh host "tmux kill-session -t build-debug"
```

- Name sessions after the task and kill them when done.
- Commands sent with `send-keys` run in the host's login shell (Fish); keep
  them Fish-compatible or wrap them in `bash -c '...'`.
