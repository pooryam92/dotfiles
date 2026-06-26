"""cli — argument handling, --json, plain output, and launching the TUI.

`main` wires the pieces: find history → parse events → (optionally window by
--days) → build the profile → emit it as JSON, a plain report, or the TUI.
"""

import json
import os
import sys

import tui

from . import __version__, content
from .aliases import read_aliases
from .history import history_path, read_events
from .profile import build_profile


def parse_args(argv):
    opts = {"json": False, "plain": False, "days": None, "limit": 15, "histfile": None}
    it = iter(argv)
    for a in it:
        if a == "--json":
            opts["json"] = True
        elif a in ("--plain", "--no-tui"):
            opts["plain"] = True
        elif a == "--days":
            opts["days"] = int(next(it))
        elif a == "--limit":
            opts["limit"] = int(next(it))
        elif a == "--histfile":
            opts["histfile"] = next(it)
        else:
            raise SystemExit(f"keymap: unknown argument {a!r} (try --json / --plain / --days N)")
    return opts


def run_tui(p):
    """Pick a view on the left (j/k), read it on the right — same browser as cheat."""
    views = [
        ("Overview", lambda: content.doc_overview(p)),
        ("Top commands", lambda: content.doc_top(p)),
        ("Subcommands", lambda: content.doc_subs(p)),
        ("Aliases", lambda: content.doc_aliases(p)),
    ]
    items = [tui.Item(name, fn) for name, fn in views]
    tui.browse(items, title="keymap", subtitle="j/k pick · l read · q quit",
               list_width=22, smoke_env="KEYMAP_SMOKE")


def main():
    argv = sys.argv[1:]
    if argv and argv[0] in ("version", "--version", "-v"):
        print(f"keymap {__version__}")
        return
    opts = parse_args(argv)
    if opts["histfile"]:
        os.environ["KEYMAP_HISTFILE"] = opts["histfile"]

    path = history_path()
    if not path or not path.exists():
        sys.exit("keymap: no shell history found "
                 "(looked for ~/.zsh_history / PSReadLine; set $KEYMAP_HISTFILE to override)")

    events = list(read_events(path))
    if opts["days"] is not None:
        import time
        cutoff = time.time() - opts["days"] * 86400
        events = [(t, c) for (t, c) in events if t is None or t >= cutoff]

    profile = build_profile(events, read_aliases(), limit=opts["limit"])
    profile["meta"]["source"] = str(path)

    if opts["json"]:
        json.dump(profile, sys.stdout, ensure_ascii=False, indent=2)
        sys.stdout.write("\n")
        return
    if opts["plain"] or not sys.stdout.isatty():
        sys.stdout.write(tui.render_ansi(content.render_plain(profile), sys.stdout.isatty()) + "\n")
        return
    try:
        import textual  # noqa: F401
    except ImportError:
        sys.stdout.write(tui.render_ansi(content.render_plain(profile), True) + "\n")  # graceful
        return
    run_tui(profile)
