"""render — turn a neutral Doc into a concrete face.

Two renderers, one palette. `render_ansi` powers plain / piped output and needs
nothing installed. `render_markup` produces Textual/rich markup for the TUI pane
and imports rich lazily (it rides with Textual in the venv). Swapping the TUI
framework means writing a third renderer here and re-pointing browse.py — the
tools, which only ever build Docs, never change.
"""

# Tokyo Night — the same hexes WezTerm's scheme and Starship use, so the tools
# look native. Two channels per style: rich markup for the Textual pane, ANSI
# SGR for plain mode. `None` means "leave it the terminal/theme default".
_MARKUP = {
    "title": "b #7aa2f7", "key": "#7dcfff", "text": None,
    "dim": "#565f89", "accent": "#e0af68", "match": "b #e0af68",
}
_ANSI = {
    "title": "1;34", "key": "36", "text": None,
    "dim": "38;5;245", "accent": "33", "match": "1;33",
}


def render_ansi(doc, tty=True):
    """Render a Doc to a plain string — ANSI-coloured when `tty`, else bare text.

    Deliberately dumb: it concatenates each line's spans with no separators and
    joins lines with newlines, so the tool controls every space and indent. That
    keeps this honest and makes piped output (tty=False) byte-clean."""
    out = []
    for line in doc.lines:
        buf = []
        for style, txt in line:
            code = _ANSI.get(style)
            buf.append(f"\033[{code}m{txt}\033[0m" if code and tty else txt)
        out.append("".join(buf))
    return "\n".join(out)


def render_markup(doc):
    """Render a Doc to Textual/rich markup. Escapes every span's text here so
    tools never deal with markup syntax. Imported lazily — rich rides with
    Textual in the venv and isn't needed for the plain paths."""
    from rich.markup import escape
    return "\n".join(markup_line(line, escape) for line in doc.lines)


def markup_line(line, escape):
    """One line of spans → a markup string (the list widget reuses this for its
    row labels, which are single lines, not whole Docs)."""
    buf = []
    for style, txt in line:
        tag = _MARKUP.get(style)
        esc = escape(txt)
        buf.append(f"[{tag}]{esc}[/]" if tag else esc)
    return "".join(buf)
