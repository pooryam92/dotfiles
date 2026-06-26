"""parse — tokenize a command line into (program, subcommand).

Sees *through* wrappers (sudo/env/…) and FOO=bar prefixes to the command you
really ran, and breaks out a meaningful subcommand for tools where the second
word matters (git commit, docker run, …).
"""

import os
import re
import shlex

# Wrappers to look *through* to find the command the user really ran.
_WRAPPERS = {"sudo", "command", "time", "nohup", "env", "doas", "exec", "builtin", "\\"}
# Tools whose second word is a meaningful subcommand worth breaking out.
_SUBCMD_TOOLS = {
    "git", "docker", "kubectl", "cargo", "npm", "pnpm", "yarn", "go", "gh", "pip",
    "pip3", "brew", "apt", "apt-get", "systemctl", "tmux", "wezterm", "z", "zoxide",
    "claude", "code", "zed", "conda", "uv", "poetry", "rustup", "terraform",
}

_ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")


def _split(cmd: str):
    """Best-effort tokenization; shlex first, dumb split if it chokes."""
    try:
        return shlex.split(cmd, comments=False, posix=True)
    except ValueError:
        return cmd.split()


def parse(cmd: str):
    """Return (program, subcommand|None) for a command line, or (None, None).

    Skips leading wrappers (sudo/env/…) and FOO=bar assignments, basenames the
    program, and pulls the first non-flag word as a subcommand for known tools.
    """
    toks = _split(cmd)
    i = 0
    while i < len(toks):
        t = toks[i]
        if t in _WRAPPERS or _ASSIGN.match(t):
            i += 1
            continue
        break
    if i >= len(toks):
        return None, None
    prog = os.path.basename(toks[i].strip("\"'"))
    if not prog or prog.startswith("-"):
        return None, None
    sub = None
    if prog in _SUBCMD_TOOLS:
        for t in toks[i + 1:]:
            if not t.startswith("-"):
                sub = t
                break
    return prog, sub


def clean_toks(cmd: str):
    """Tokens with wrappers (sudo/env/…) and FOO=bar prefixes stripped, lowercased.

    Flags are *kept* — so `ls -A` and `ls -lah` stay distinct, which matters when
    deciding whether you typed the exact long form an alias would have saved."""
    toks = _split(cmd)
    i = 0
    while i < len(toks) and (toks[i] in _WRAPPERS or _ASSIGN.match(toks[i])):
        i += 1
    return [t.lower() for t in toks[i:]]
