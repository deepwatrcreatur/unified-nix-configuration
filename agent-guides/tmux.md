# tmux for Remote and Long-Running Work

Use a named tmux session when a command must outlive your SSH connection or
your agent turn (long builds, servers, monitoring).

```bash
# Create a named session on a host
ssh host "tmux new-session -d -s build-debug"

# Run a command in it without attaching
ssh host "tmux send-keys -t build-debug 'cd ~/flakes/unified-nix-configuration' Enter"

# Separate windows for separate concerns
ssh host "tmux new-window -t build-debug -n server"
ssh host "tmux send-keys -t build-debug:server 'ollama serve' Enter"

# Check, attach, clean up
ssh host "tmux list-sessions | grep build-debug"
ssh -t host "tmux attach-session -t build-debug"
ssh host "tmux kill-session -t build-debug"
```

Practices:

- Name sessions after the task (`inference-test`, `build-debug`,
  `service-monitor`) and check whether one exists before creating it.
- Use one window per concern: server, testing, monitoring.
- Kill sessions when the work is done.
- Most hosts run Fish. Commands sent with `send-keys` run in that shell, so
  keep them Fish-compatible or wrap them in `bash -c '...'`.
