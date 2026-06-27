"""cli — argument handling, plain-text output, and launching the TUI.

The decision tree (in `main`): explicit args print once and exit (great for
pipes); a bare invocation opens the Textual TUI, falling back to a plain menu
loop without Textual and to a one-shot index dump when stdout isn't a terminal.
"""

import sys

import tui

from . import __version__, content
from .data import in_cat, load, match_cat


def _emit(doc):
    sys.stdout.write(tui.render_ansi(doc, sys.stdout.isatty()) + "\n")


def plain_tip(rows):
    _emit(content.doc_tip(rows))


def plain_oneshot(cats, rows, args):
    """cheat <category|all|word…> — print once (used for args & non-tty)."""
    joined = " ".join(args)
    if joined.lower() == "all":
        _emit(content.doc_lesson(cats, rows, "all"))
    elif (m := match_cat(cats, joined)):
        _emit(content.doc_lesson(cats, rows, m))
    else:
        _emit(content.doc_search(rows, joined))


def plain_menu(cats, rows):
    """Interactive fallback when Textual is missing — mirrors cheat.lua's loop."""
    while True:
        _emit(content.doc_index(cats, rows))
        try:
            line = input("\n  pick a number · /word to search · q quit › ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if line in ("", "q", "quit"):
            break
        if line.isdigit():
            i = int(line)
            if 1 <= i <= len(cats):
                _emit(content.doc_lesson(cats, rows, cats[i - 1][0]))
            else:
                print(f"  no category #{line}")
        elif line.startswith("/"):
            _emit(content.doc_search(rows, line[1:]))
        elif (m := match_cat(cats, line)):
            _emit(content.doc_lesson(cats, rows, m))
        else:
            _emit(content.doc_search(rows, line))


def run_tui(cats, rows):
    """Left list = categories, detail pane = that category's lesson, `/` filters.
    Everything framework-specific is in tui.browse; here we just supply content."""
    items = []
    for cat, blurb in cats:
        n = len(in_cat(rows, cat))
        # The count rides in the row's htop meter now (browse sizes the bar from
        # `value`), so the label is just the name.
        items.append(tui.Item([tui.text(cat.lower())],
                              lambda c=cat: content.doc_lesson(cats, rows, c),
                              title=cat.lower(), value=n))
    tui.browse(
        items,
        title="cheat",
        subtitle=f"{len(cats)} categories",
        search=lambda q: content.doc_search(rows, q),
        list_width=30,
        list_title=f"categories [{len(cats)}]",
        smoke_env="CHEAT_SMOKE",
        shot_env="CHEAT_SHOT",
    )


def main():
    args = sys.argv[1:]
    if args and args[0] in ("version", "--version", "-v"):
        print(f"cheat {__version__}")
        return
    try:
        cats, rows = load()
    except FileNotFoundError as e:
        sys.exit(f"cheat: data file missing ({e.filename}); is the repo linked?")

    if args and args[0] == "tip":  # one random tip (the shells' once-a-day nudge)
        plain_tip(rows)
        return
    if args:  # one-shot: print and exit (also good for pipes)
        plain_oneshot(cats, rows, args)
        return
    if not sys.stdout.isatty():  # piped/redirected with no args → dump the index
        sys.stdout.write(tui.render_ansi(content.doc_index(cats, rows), False) + "\n")
        return
    try:
        import textual  # noqa: F401
    except ImportError:
        plain_menu(cats, rows)  # graceful: works before `pipx install textual`
        return
    run_tui(cats, rows)
