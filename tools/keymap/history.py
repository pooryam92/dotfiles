"""history — locate the shell-history file and parse it into events.

Data source by OS (override with $KEYMAP_HISTFILE):
  Linux / zsh    ~/.zsh_history   (EXTENDED_HISTORY timestamps drive --days/span)
  Windows / pwsh PSReadLine's ConsoleHost_history.txt   (no timestamps)
"""

import os
import re
from pathlib import Path


def history_path() -> Path | None:
    """Resolve the shell-history file: $KEYMAP_HISTFILE, else per-OS default."""
    env = os.environ.get("KEYMAP_HISTFILE")
    if env:
        return Path(env)
    if os.name == "nt":  # Windows / PowerShell — PSReadLine's flat history
        base = os.environ.get("APPDATA")
        if base:
            p = Path(base) / "Microsoft/Windows/PowerShell/PSReadLine/ConsoleHost_history.txt"
            if p.exists():
                return p
        return None
    # Linux / macOS / zsh
    hf = os.environ.get("HISTFILE")
    if hf and Path(hf).exists():
        return Path(hf)
    p = Path.home() / ".zsh_history"
    return p if p.exists() else None


# zsh EXTENDED_HISTORY line:  ": <epoch>:<elapsed>;<command>"
_ZSH_META = re.compile(r"^: (\d+):\d+;(.*)$", re.DOTALL)


def read_events(path: Path):
    """Yield (timestamp|None, command) pairs from a history file.

    Handles zsh's extended format (with epoch timestamps) and plain one-line-per-
    command files (PSReadLine, or zsh without EXTENDED_HISTORY → ts is None).
    Multi-line commands — zsh escapes the newline with a trailing backslash — are
    stitched back into a single logical command.
    """
    raw = path.read_bytes().decode("utf-8", "replace")
    cur_ts, cur_cmd, have = None, [], False

    def flush():
        if have:
            cmd = "\n".join(cur_cmd).rstrip("\n")
            if cmd.strip():
                yield cur_ts, cmd

    for line in raw.split("\n"):
        m = _ZSH_META.match(line)
        if m or (not have):
            # Start of a new record (a ": ts;" line, or the very first line of a
            # plain file). Emit whatever we were accumulating first.
            yield from flush()
            if m:
                cur_ts = int(m.group(1))
                cur_cmd = [m.group(2)]
            else:
                cur_ts = None
                cur_cmd = [line]
            have = True
        else:
            # Continuation of a multi-line command (previous line ended with "\").
            if cur_cmd and cur_cmd[-1].endswith("\\"):
                cur_cmd[-1] = cur_cmd[-1][:-1]
                cur_cmd.append(line)
            else:
                yield from flush()
                cur_ts, cur_cmd = None, [line]
    yield from flush()
