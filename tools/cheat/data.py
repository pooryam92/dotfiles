"""data — load and query the cheat sheet's two TSVs.

Files are resolved next to this package (the installer keeps them together),
overridable with $CHEAT_DIR.
"""

import os
from pathlib import Path


def data_dir() -> Path:
    """Where cheat.tsv / cheat-index.tsv live: $CHEAT_DIR, else next to us."""
    env = os.environ.get("CHEAT_DIR")
    return Path(env) if env else Path(__file__).resolve().parent


def load():
    """Return (cats, rows): cats=[(name, blurb)], rows=[{cat,key,act,tip}]."""
    d = data_dir()
    cats, rows = [], []
    for line in (d / "cheat-index.tsv").read_text(encoding="utf-8").splitlines():
        if line.strip():
            f = line.split("\t")
            cats.append((f[0], f[1] if len(f) > 1 else ""))
    for line in (d / "cheat.tsv").read_text(encoding="utf-8").splitlines():
        if line.strip():
            f = (line.split("\t") + ["", "", "", ""])[:4]
            rows.append({"cat": f[0], "key": f[1], "act": f[2], "tip": f[3]})
    return cats, rows


def match_cat(cats, s):
    """Case-insensitive category lookup; returns the canonical name or None."""
    s = s.lower()
    for name, _ in cats:
        if name.lower() == s:
            return name
    return None


def in_cat(rows, cat):
    return [r for r in rows if r["cat"].lower() == cat.lower()]
