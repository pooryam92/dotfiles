"""aliases — discover the user's aliases & functions from the shell config.

Returns {name: expansion|None}; expansion is None for shell functions. Best
effort and intentionally shallow — the agent does the real reasoning, this just
gives it (and the report) a list to cross-check against usage.
"""

import os
import re
from pathlib import Path


def read_aliases():
    out: dict[str, str | None] = {}
    if os.name == "nt":
        cfg = Path.home() / "Documents/PowerShell/profile.ps1"
        if not cfg.exists():
            cfg = Path.home() / "Documents/WindowsPowerShell/profile.ps1"
        if cfg.exists():
            txt = cfg.read_text("utf-8", "replace")
            for m in re.finditer(r"(?im)^\s*Set-Alias\s+(?:-Name\s+)?(\S+)\s+(?:-Value\s+)?(\S+)", txt):
                out[m.group(1)] = m.group(2)
            for m in re.finditer(r"(?im)^\s*function\s+([A-Za-z0-9_-]+)", txt):
                out.setdefault(m.group(1), None)
        return out
    cfg = Path.home() / ".zshrc"
    if cfg.exists():
        txt = cfg.read_text("utf-8", "replace")
        for m in re.finditer(r"""(?m)^\s*alias\s+([^\s=]+)=(['"]?)(.*?)\2\s*$""", txt):
            out[m.group(1)] = m.group(3)
        for m in re.finditer(r"(?m)^\s*(?:function\s+)?([A-Za-z0-9_-]+)\s*\(\)\s*\{", txt):
            out.setdefault(m.group(1), None)
    return out
