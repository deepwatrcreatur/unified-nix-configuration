"""Policy tests for scripts/agent-guard.py. Run: python3 tests/agent-guard-test.py <guard>"""

import importlib.util
import io
import json
import sys

spec = importlib.util.spec_from_file_location("agent_guard", sys.argv[1])
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)

ALLOW = [
    "ls -la",
    "git status",
    "git branch -d merged-branch",
    "git push origin feat-f",
    "git push -u origin feature/x",
    "git push origin main",
    "git reset --soft HEAD~1",
    "git clean -n",
    "git stash push -u -m tag",
    "git worktree remove ../wt",
    "rm file.txt",
    "rm -f result",
    "rm -rf node_modules dist .direnv",
    "rm -rf /tmp/claude-1000/scratch/x",
    "find /tmp/x -name '*.o' -delete",
    "grep -r 'git reset --hard' docs/",
    "echo 'rm -rf /' > note.txt",
    "rtk git log --oneline -5",
    "nix build .#foo && nix copy --to ssh-ng://host ./result",
    "ssh router systemctl is-active kea-dhcp4-server",
    "gh api repos/o/r -X PATCH -F x=1",
    "gh pr merge 12 --merge",
    "psql -c 'select * from t where id=1'",
    "docker ps -a",
    "zfs list",
    "qm list",
    "nix-collect-garbage --delete-older-than 30d",
    "cat > f <<'EOF'\nhello 'unbalanced\nEOF",
    "",
]

ASK = [
    "git branch -D old",
    "git branch --delete --force old",
    "git push --force origin main",
    "git push -f",
    "git push origin +main",
    "git push --force-with-lease",
    "git push origin --delete old",
    "git push origin :old",
    "git reset --hard origin/main",
    "git clean -fdx",
    "git stash drop",
    "git worktree remove --force ../wt",
    "git -C repo reset --hard",
    "rm -rf src",
    "rm -r -f ./docs",
    "sudo rm -rf /var/lib/foo",
    "cd x && rm -rf build src",
    "ssh host 'rm -rf /srv/data'",
    "ssh -o BatchMode=yes host sudo zfs destroy tank/x",
    "bash -c 'git reset --hard'",
    "timeout 30 git push -f",
    "env FOO=1 git clean -f",
    "xargs -a list.txt git push -q origin --delete",
    "xargs git branch -D < branches",
    "find . -name '*.bak' -delete",
    "mkfs.ext4 /dev/sdb1",
    "dd if=img of=/dev/sda bs=4M",
    "wipefs -a /dev/sdb",
    "sgdisk --zap-all /dev/sdb",
    "qm destroy 100",
    "ssh root@pve pct destroy 104",
    "btrfs subvolume delete /home/.snapshots/1/snapshot",
    "podman system prune -a",
    "docker volume rm data",
    "kubectl delete pod x",
    "gh repo delete o/r --yes",
    "gh api -X DELETE repos/o/r/git/refs/heads/x",
    "gh api --method=DELETE repos/o/r",
    "psql -c 'DROP TABLE users'",
    "sqlite3 db.sqlite 'delete from items'",
    "nix-collect-garbage -d",
    "systemd-run --unit=x git reset --hard",
    "pct exec 104 -- rm -rf /var/lib/roundtable",
]

DENY = [
    "rm -rf /",
    "rm -rf ~",
    "rm -rf $HOME",
    "sudo rm -rf /nix",
    "rm -rf /etc/",
    "ssh host 'sudo rm -rf /'",
]

failures = []
for expected, cases in (("allow", ALLOW), ("ask", ASK), ("deny", DENY)):
    for cmd in cases:
        got, reason = guard.evaluate(cmd)
        if got != expected:
            failures.append(f"expected {expected}, got {got} ({reason}): {cmd!r}")


def run_hook(payload):
    old_in, old_out = sys.stdin, sys.stdout
    sys.stdin, sys.stdout = io.StringIO(json.dumps(payload)), io.StringIO()
    try:
        code = guard.main(["agent-guard"])
        return code, sys.stdout.getvalue()
    finally:
        sys.stdin, sys.stdout = old_in, old_out


code, out = run_hook({"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": "git branch -D x"}})
data = json.loads(out)["hookSpecificOutput"]
if code != 0 or data["permissionDecision"] != "ask" or data["hookEventName"] != "PreToolUse":
    failures.append(f"claude hook output wrong: {code} {out!r}")
code, out = run_hook({"hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": {"command": "ls"}})
if code != 0 or out.strip():
    failures.append(f"claude allow should be silent: {code} {out!r}")
old_err = sys.stderr
sys.stderr = io.StringIO()
code, _ = run_hook({"hook_event_name": "BeforeTool", "tool_name": "run_shell_command", "tool_input": {"command": "rm -rf src"}})
sys.stderr = old_err
if code != 2:
    failures.append(f"gemini block should exit 2, got {code}")

total = len(ALLOW) + len(ASK) + len(DENY)
if failures:
    print("\n".join(failures))
    print(f"{len(failures)} of {total} policy cases (plus hook checks) failed")
    sys.exit(1)
print(f"agent-guard policy: {total} cases and hook output checks passed")
