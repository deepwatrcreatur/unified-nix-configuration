"""Destructive command guard for coding agents.

Runs as a Claude Code PreToolUse hook (and optionally a Gemini CLI BeforeTool
hook) on shell commands. Commands that destroy data or rewrite shared history
are sent back for confirmation ("ask"); a few that are never intended, such as
a recursive delete of / or $HOME, are refused outright ("deny"). Everything
else is allowed silently.

Usage:
  agent-guard                 read a hook payload (JSON) on stdin
  agent-guard check CMD...    print the decision for CMD; exit 0 allow,
                              1 ask, 2 deny (for testing)

Set AGENT_GUARD_SKIP=1 in the agent's environment to disable the guard.
"""

import json
import os
import re
import shlex
import sys

ALLOW, ASK, DENY = "allow", "ask", "deny"
RANK = {ALLOW: 0, ASK: 1, DENY: 2}

SEPARATORS = {";", "&", "&&", "|", "||", "|&", "\n", "(", ")", ";;"}
REDIRECTS = re.compile(r"^[0-9]*(>|>>|<|<<|<<<|>&|<&|&>|&>>)$")
ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")

# Wrappers whose remaining arguments are another command. The value is the set
# of options that take a separate argument, so the wrapped command is found.
WRAPPERS = {
    "sudo": {"-u", "-g", "-C", "-D", "-h", "-p", "-r", "-t", "-U"},
    "doas": {"-u", "-C"},
    "env": {"-u", "-C", "-S"},
    "nice": {"-n"},
    "ionice": {"-c", "-n", "-p"},
    "nohup": set(),
    "time": set(),
    "command": set(),
    "exec": set(),
    "builtin": set(),
    "rtk": set(),
    "xargs": {"-a", "-d", "-E", "-I", "-L", "-n", "-P", "-s"},
    "stdbuf": {"-i", "-o", "-e"},
    "setsid": set(),
    "chronic": set(),
    "flock": {"-w", "-E"},
}

SAFE_RM_BASENAMES = {
    "node_modules", ".next", "dist", "build", "coverage", "__pycache__",
    ".cache", ".direnv", ".turbo", "result", "target", ".pytest_cache",
    ".mypy_cache", ".ruff_cache",
}
SAFE_RM_PREFIXES = ("/tmp/", "/var/tmp/")
DENY_RM_TARGETS = {
    "/", "/*", "~", "~/", "~/*", "$HOME", "$HOME/", "${HOME}", "${HOME}/",
    "/home", "/home/", "/root", "/nix", "/nix/", "/nix/store", "/etc",
    "/etc/", "/boot", "/boot/", "/usr", "/usr/", "/var", "/var/", "/bin",
    "/lib", "/srv", "/mnt", "/persist",
}

DB_CLIENTS = {"psql", "mysql", "mariadb", "sqlite3", "duckdb", "clickhouse-client"}


def tokenize(text):
    """Split shell text into tokens, keeping separators and newlines."""
    lex = shlex.shlex(text, posix=True, punctuation_chars=";&|()<>\n")
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    lex.commenters = "#"
    return list(lex)


def split_commands(tokens):
    commands, current = [], []
    for tok in tokens:
        if tok in SEPARATORS:
            if current:
                commands.append(current)
            current = []
        else:
            current.append(tok)
    if current:
        commands.append(current)
    return commands


def strip_redirects(argv):
    out, skip = [], False
    for tok in argv:
        if skip:
            skip = False
            continue
        if REDIRECTS.match(tok):
            skip = True
            continue
        out.append(tok)
    return out


def unwrap(argv):
    """Remove env assignments and wrapper commands; return (argv, nested)."""
    nested = []
    while argv:
        while argv and ASSIGNMENT.match(argv[0]):
            argv = argv[1:]
        if not argv:
            break
        name = os.path.basename(argv[0])
        if name in WRAPPERS:
            takes_value = WRAPPERS[name]
            i = 1
            while i < len(argv) and argv[i].startswith("-") and argv[i] != "--":
                if argv[i] in takes_value:
                    i += 1
                i += 1
            if i < len(argv) and argv[i] == "--":
                i += 1
            argv = argv[i:]
            continue
        if name == "timeout":
            i = 1
            while i < len(argv) and argv[i].startswith("-"):
                i += 2 if argv[i] in ("-s", "-k", "--signal", "--kill-after") else 1
            argv = argv[i + 1:]
            continue
        if name in ("bash", "sh", "zsh", "fish", "dash") and "-c" in argv[1:]:
            idx = argv.index("-c")
            if idx + 1 < len(argv):
                nested.append(argv[idx + 1])
            return [], nested
        if name == "ssh":
            # ssh [options] host command...
            i, value_opts = 1, set("BbcDEeFIiJLlmOoPpQRSWw")
            while i < len(argv) and argv[i].startswith("-"):
                flag = argv[i]
                if len(flag) == 2 and flag[1] in value_opts:
                    i += 1
                i += 1
            if i + 1 < len(argv):
                nested.append(" ".join(argv[i + 1:]))
            return [], nested
        if name in ("pct", "lxc-attach") and len(argv) > 2 and argv[1] == "exec":
            if "--" in argv:
                return argv[argv.index("--") + 1:], nested
        if name == "systemd-run":
            i = 1
            while i < len(argv) and argv[i].startswith("-"):
                if argv[i] in ("-u", "-p", "-E", "-M", "-H", "--unit", "--property"):
                    i += 1
                i += 1
            argv = argv[i:]
            continue
        if name == "nix" and len(argv) > 1 and argv[1] in ("shell", "develop"):
            for flag in ("-c", "--command"):
                if flag in argv:
                    argv = argv[argv.index(flag) + 1:]
                    break
            else:
                return argv, nested
            continue
        break
    return argv, nested


def short_flags(args):
    """Collect single-letter flags from args like -rf, -r -f."""
    letters = set()
    for a in args:
        if a == "--":
            break
        if a.startswith("-") and not a.startswith("--") and len(a) > 1:
            letters.update(a[1:])
    return letters


def positional(args):
    out, after_dd = [], False
    for a in args:
        if after_dd:
            out.append(a)
        elif a == "--":
            after_dd = True
        elif not a.startswith("-"):
            out.append(a)
    return out


def check_rm(args):
    flags = short_flags(args)
    recursive = bool(flags & {"r", "R"}) or "--recursive" in args
    if not recursive:
        return ALLOW, ""
    targets = positional(args)
    for t in targets:
        if t.rstrip("/") in {d.rstrip("/") for d in DENY_RM_TARGETS} or t in DENY_RM_TARGETS:
            return DENY, f"recursive delete of {t}"
    risky = []
    for t in targets:
        base = os.path.basename(t.rstrip("/"))
        if base in SAFE_RM_BASENAMES or t.startswith(SAFE_RM_PREFIXES):
            continue
        risky.append(t)
    if risky:
        return ASK, "recursive delete of " + " ".join(risky[:5])
    return ALLOW, ""


def check_git(args):
    i = 0
    while i < len(args) and args[i].startswith("-"):
        if args[i] in ("-C", "-c", "--git-dir", "--work-tree", "--namespace"):
            i += 1
        i += 1
    if i >= len(args):
        return ALLOW, ""
    sub, rest = args[i], args[i + 1:]
    flags = short_flags(rest)
    if sub == "push":
        if (
            "f" in flags
            or any(a.startswith(("--force", "--mirror")) for a in rest)
            or any(a.startswith("+") for a in positional(rest))
        ):
            return ASK, "git force-push rewrites remote history"
        if "d" in flags or "--delete" in rest or "--prune" in rest or any(
            a.startswith(":") and len(a) > 1 for a in positional(rest)
        ):
            return ASK, "git push deletes remote branches or tags"
    if sub == "reset" and "--hard" in rest:
        return ASK, "git reset --hard discards uncommitted changes"
    if sub == "clean" and ("f" in flags or "--force" in rest):
        return ASK, "git clean deletes untracked files"
    if sub == "branch" and ("D" in flags or ("--delete" in rest and ("--force" in rest or "f" in flags))):
        return ASK, "git branch -D deletes branches even if unmerged"
    if sub == "stash" and rest[:1] and rest[0] in ("drop", "clear"):
        return ASK, f"git stash {rest[0]} discards stashed work"
    if sub == "worktree" and rest[:1] == ["remove"] and ("f" in flags or "--force" in rest):
        return ASK, "git worktree remove --force discards worktree changes"
    if sub in ("filter-branch", "filter-repo"):
        return ASK, f"git {sub} rewrites history"
    if sub == "reflog" and rest[:1] in (["expire"], ["delete"]):
        return ASK, "git reflog expiry removes recovery points"
    if sub == "update-ref" and "d" in flags:
        return ASK, "git update-ref -d deletes a ref"
    if sub in ("checkout", "restore") and ("f" in flags or "--force" in rest) and "." in rest:
        return ASK, f"git {sub} discards working tree changes"
    return ALLOW, ""


def check_sql(name, args, raw_lower):
    if name not in DB_CLIENTS:
        return ALLOW, ""
    text = " ".join(args).lower() + " " + raw_lower
    if re.search(r"\bdrop\s+(table|database|schema)\b", text):
        return ASK, "SQL DROP removes database objects"
    if re.search(r"\btruncate\b", text):
        return ASK, "SQL TRUNCATE removes all rows"
    if re.search(r"\bdelete\s+from\b", text) and not re.search(r"\bwhere\b", text):
        return ASK, "SQL DELETE without WHERE removes all rows"
    return ALLOW, ""


def check_simple(argv, raw_lower):
    if not argv:
        return ALLOW, ""
    name = os.path.basename(argv[0])
    args = argv[1:]
    sub = args[0] if args else ""
    sub2 = args[1] if len(args) > 1 else ""

    if name == "rm":
        return check_rm(args)
    if name == "git":
        return check_git(args)
    if name == "find" and "-delete" in args:
        roots = [a for a in args if not a.startswith(("-", "(", ")", "!"))][:1]
        if roots and roots[0].startswith(SAFE_RM_PREFIXES):
            return ALLOW, ""
        return ASK, "find -delete removes matching files"
    if name.startswith("mkfs") or name in ("wipefs", "blkdiscard", "sfdisk", "parted"):
        return ASK, f"{name} rewrites disks or partitions"
    if name == "dd" and any(a.startswith("of=/dev/") for a in args):
        return ASK, "dd writes directly to a block device"
    if name in ("sgdisk", "gdisk") and any(a in ("-Z", "--zap-all", "-o", "--clear", "-z", "--zap") for a in args):
        return ASK, f"{name} wipes a partition table"
    if name == "zpool" and sub in ("destroy", "labelclear"):
        return ASK, f"zpool {sub} destroys a pool"
    if name == "zfs" and sub == "destroy":
        return ASK, "zfs destroy deletes datasets or snapshots"
    if name == "btrfs" and sub in ("subvolume", "sub", "su") and sub2 in ("delete", "del", "de"):
        return ASK, "btrfs subvolume delete removes data"
    if name in ("lvremove", "vgremove", "pvremove"):
        return ASK, f"{name} deletes LVM volumes"
    if name == "cryptsetup" and sub in ("luksFormat", "erase", "luksErase"):
        return ASK, f"cryptsetup {sub} destroys encrypted data"
    if name in ("qm", "pct") and sub == "destroy":
        return ASK, f"{name} destroy deletes a Proxmox guest"
    if name == "pvesm" and sub == "free":
        return ASK, "pvesm free deletes a Proxmox volume"
    if name in ("docker", "podman"):
        if sub == "system" and sub2 == "prune":
            return ASK, f"{name} system prune deletes containers, images and volumes"
        if sub == "volume" and sub2 in ("rm", "prune"):
            return ASK, f"{name} volume {sub2} deletes volume data"
    if name == "kubectl" and sub == "delete":
        return ASK, "kubectl delete removes cluster resources"
    if name == "gh":
        if sub in ("repo", "release") and sub2 == "delete":
            return ASK, f"gh {sub} delete is irreversible"
        if sub == "api":
            method = None
            for j, a in enumerate(args):
                if a in ("-X", "--method") and j + 1 < len(args):
                    method = args[j + 1]
                elif a.startswith("--method="):
                    method = a.split("=", 1)[1]
                elif a.startswith("-X") and len(a) > 2:
                    method = a[2:]
            if method and method.upper() == "DELETE":
                return ASK, "gh api DELETE removes GitHub resources"
    if name in ("nix-collect-garbage",) and ("-d" in args or "--delete-old" in args):
        return ASK, "nix-collect-garbage -d removes all rollback generations"
    return check_sql(name, args, raw_lower)


def evaluate(command, depth=0):
    if depth > 4 or not command.strip():
        return ALLOW, ""
    raw_lower = command.lower()
    try:
        tokens = tokenize(command)
    except ValueError:
        # Unbalanced quotes (for example in a heredoc body): fall back to a
        # plain split so obvious patterns are still caught.
        tokens = command.replace(";", " ; ").replace("&&", " && ").replace("|", " | ").split()
    best = (ALLOW, "")
    for argv in split_commands(tokens):
        argv, nested = unwrap(strip_redirects(argv))
        results = [check_simple(argv, raw_lower)]
        results += [evaluate(n, depth + 1) for n in nested]
        for decision, reason in results:
            if RANK[decision] > RANK[best[0]]:
                best = (decision, reason)
                if decision == DENY:
                    return best
    return best


def main(argv):
    if argv[1:2] == ["check"]:
        decision, reason = evaluate(" ".join(argv[2:]))
        print(f"{decision}: {reason}" if reason else decision)
        return {ALLOW: 0, ASK: 1, DENY: 2}[decision]

    if os.environ.get("AGENT_GUARD_SKIP") == "1":
        return 0
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        return 0
    tool_input = payload.get("tool_input") or {}
    command = tool_input.get("command") or tool_input.get("cmd") or ""
    if not isinstance(command, str) or not command:
        return 0

    decision, reason = evaluate(command)
    if decision == ALLOW:
        return 0
    if decision == DENY:
        message = f"[agent-guard] Refused: {reason}. This is never run by an agent."
    else:
        message = f"[agent-guard] {reason}. Confirm only if this is intended."

    if payload.get("hook_event_name") == "BeforeTool":
        # Gemini CLI: exit 2 blocks the tool call and shows stderr.
        print(message, file=sys.stderr)
        return 2

    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": decision,
                "permissionDecisionReason": message,
            }
        },
        sys.stdout,
    )
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
