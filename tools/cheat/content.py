"""content — build the cheat screens as framework-neutral `tui.Doc`s.

Every screen (the index, a lesson, search results, a tip) is a Doc, so the same
builder feeds both plain output (`tui.render_ansi`) and the TUI's detail pane.
Nothing here imports Textual.
"""

import random

import tui

from .data import in_cat


def doc_index(cats, rows):
    """The category list with blurbs and counts — plain mode's home screen.
    (The TUI shows this as its left-hand list instead; see cli.run_tui.)"""
    d = tui.Doc().blank()
    d.line(tui.text("  "), tui.title("cheat"),
           tui.text(" — learn the terminal, one category at a time")).blank()
    for i, (cat, blurb) in enumerate(cats, 1):
        n = len(in_cat(rows, cat))
        d.line(tui.text("  "), tui.key(f"{i:2d}"), tui.text("  "),
               tui.key(f"{cat.lower():<9}"), tui.text(f" {blurb:<40} "),
               tui.dim(f"({n})"))
    return d.blank()


def doc_lesson(cats, rows, want):
    """One category's entries (or all of them) — the detail pane / `cheat <cat>`."""
    blurbs = {c.lower(): b for c, b in cats}
    d, cur = tui.Doc(), None
    for r in rows:
        if want == "all" or r["cat"].lower() == want.lower():
            if r["cat"] != cur:
                cur = r["cat"]
                d.blank().line(tui.title(r["cat"]), tui.text("  "),
                               tui.dim(blurbs.get(r["cat"].lower(), ""))).blank()
            d.line(tui.text("  "), tui.key(f"{r['key']:<16}"), tui.text(f" {r['act']}"))
            if r["tip"]:
                d.line(tui.text("  " + " " * 16 + " "), tui.dim(f"→ {r['tip']}"))
    return d


def doc_search(rows, q):
    """Entries matching `q`, with the hit highlighted — `cheat <word>` / `/`."""
    hits = [r for r in rows
            if q.lower() in f"{r['cat']} {r['key']} {r['act']} {r['tip']}".lower()]
    d = tui.Doc().blank()
    if not hits:
        return d.line(tui.dim("   no matches for "), tui.accent(q)).blank()
    n = len(hits)
    d.line(tui.dim(f"   {n} match{'' if n == 1 else 'es'} for "), tui.accent(q)).blank()
    for r in hits:
        d.line(tui.text("   "), tui.dim(f"{r['cat'].lower():<9}"), tui.text(" "),
               *tui.hl(f"{r['key']:<16}", q, "key"), tui.text(" "),
               *tui.hl(r["act"], q, "text"))
    return d


def doc_tip(rows):
    """One random tip — `cheat tip` and the once-a-day shell nudge.

    Skips the self-referential opener ("cheat → open this cheat sheet") so a tip
    always teaches a real key, and points at the matching lesson so the nudge is
    one keystroke from more."""
    pool = [r for r in rows if r["key"].lower() != "cheat"] or rows
    r = random.choice(pool)
    d = tui.Doc().blank()
    d.line(tui.text("  "), tui.title("tip"), tui.text("  "),
           tui.key(r["key"]), tui.text(f"  {r['act']}"))
    if r["tip"]:
        d.line(tui.text(" " * 7), tui.dim(f"→ {r['tip']}"))
    d.line(tui.text(" " * 7), tui.dim(f"more: cheat {r['cat'].lower()}")).blank()
    return d
