"""content — render a profile as framework-neutral `tui.Doc`s.

The TUI shows one view per Doc (overview / top / subs / aliases); `render_plain`
concatenates the sections into the single report `--plain` / a pipe prints. One
source either way. Nothing here imports Textual.
"""

import tui


def _bars(d, rows, label, peak=None, width=30):
    """Append one bar row per item: name, a █-bar scaled to `peak`, and the count."""
    peak = peak or (rows[0]["count"] if rows else 0)
    for r in rows:
        n = r["count"]
        b = "█" * max(1 if n else 0, int(round(width * n / peak))) if peak else ""
        d.line(tui.text("  "), tui.key(f"{str(r[label]):<14}"), tui.text(" "),
               tui.accent(b), tui.text(" "), tui.dim(str(n)))


def doc_meta(p):
    """Header line for the plain report (the TUI uses doc_overview instead)."""
    m = p["meta"]
    span = f"{m['since']} → {m['until']}" if m["since"] else "no timestamps"
    return (tui.Doc().blank()
            .line(tui.text("  "), tui.title("keymap"),
                  tui.text(" — what you actually lean on"))
            .line(tui.text("  "), tui.dim(
                f"{m['total_commands']} commands · {m['distinct_programs']} distinct · {span}"))
            .blank())


def doc_overview(p):
    m = p["meta"]
    span = f"{m['since']} → {m['until']}" if m["since"] else "no timestamps in history"
    top = ", ".join(f"{r['program']} ({r['count']})" for r in p["top_commands"][:3])
    unused = [a["name"] for a in p["aliases"] if a["used"] == 0]
    d = tui.Doc().line(tui.title("Overview")).blank()
    d.line(tui.text("  commands:   "), tui.key(str(m["total_commands"])),
           tui.text("  ("), tui.dim(f"{m['distinct_programs']} distinct"), tui.text(")"))
    d.line(tui.text("  span:       "), tui.dim(span))
    d.line(tui.text(f"  favourites: {top}"))
    d.line(tui.text("  unused aliases: "), tui.accent(str(len(unused)))).blank()
    d.line(tui.dim("  j/k pick a view · l read · q quit. "
                   "Run `/keymap` in Claude Code to turn this into repo changes."))
    return d


def doc_top(p):
    d = tui.Doc().line(tui.text("  "), tui.title("Top commands")).blank()
    _bars(d, p["top_commands"], "program")
    return d


def doc_subs(p):
    d = tui.Doc().line(tui.text("  "), tui.title("Subcommands"))
    if not p["subcommands"]:
        return d.blank().line(tui.text("  "), tui.dim("nothing with subcommands yet"))
    for prog, rows in p["subcommands"].items():
        d.blank().line(tui.text("  "), tui.key(prog))
        _bars(d, rows, "sub", width=22)
    return d


def doc_aliases(p):
    d = tui.Doc().line(tui.text("  "), tui.title("Aliases"), tui.text("  "),
                       tui.dim("(used / missed = times you typed the long form)")).blank()
    for a in p["aliases"]:
        if a["missed"]:
            flag = tui.accent(f"missed {a['missed']}×")
        elif a["used"] == 0:
            flag = tui.dim("unused")
        else:
            flag = tui.dim(f"used {a['used']}×")
        exp = a["expansion"] or "ƒ function"
        d.line(tui.text("  "), tui.key(f"{a['name']:<10}"), tui.text(" "),
               tui.dim(f"{exp:<26}"), tui.text(" "), flag)
    if p["alias_candidates"]:
        d.blank().line(tui.text("  "), tui.title("Worth an alias?"), tui.text("  "),
                       tui.dim("(typed often, and long)")).blank()
        for r in p["alias_candidates"][:10]:
            c = r["cmd"] if len(r["cmd"]) <= 52 else r["cmd"][:51] + "…"
            d.line(tui.text("  "), tui.dim(f"{r['count']:>3}×"), tui.text(f" {c}"))
    return d


def render_plain(p):
    """The whole report as one Doc — `--plain`, no-tty, or the no-Textual fallback."""
    d = doc_meta(p).extend(doc_top(p))
    if p["subcommands"]:
        d.blank().extend(doc_subs(p))
    if p["aliases"] or p["alias_candidates"]:
        d.blank().extend(doc_aliases(p))
    return d.blank()
