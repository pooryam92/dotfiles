"""render — turn a neutral Doc into a concrete face.

Two renderers, one palette. `render_ansi` powers plain / piped output. Both are
pure string work with no third-party imports — `render_markup` emits Textual
markup with its own escaper (`_esc`), since rich's `escape` leaves a bare `[`
unescaped and Textual's parser then leaks the surrounding tags. Swapping the TUI
framework means writing a third renderer here and re-pointing browse.py — the
tools, which only ever build Docs, never change.
"""

# Tokyo Night — the exact hexes WezTerm's built-in scheme uses, so the tools look
# native (verified against `wezterm.color.get_builtin_schemes()['Tokyo Night']`):
# blue #7aa2f7 = WezTerm's split/pane-border accent, cyan #7dcfff, yellow #e0af68,
# green #9ece6a — all straight from that palette. Two channels per style: rich
# markup for the Textual pane, ANSI SGR for plain mode. `None` means "leave it the
# terminal/theme default". `bar` is the htop meter fill — green, kept separate from
# `accent` (yellow emphasis) so it stays legible on the blue selection highlight.
_MARKUP = {
    "title": "b #7aa2f7", "key": "#7dcfff", "text": None,
    "dim": "#565f89", "accent": "#e0af68", "match": "b #e0af68", "bar": "#9ece6a",
}
_ANSI = {
    "title": "1;34", "key": "36", "text": None,
    "dim": "38;5;245", "accent": "33", "match": "1;33", "bar": "32",
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
    """Render a Doc to Textual markup. Escapes every span's text here so tools
    never deal with markup syntax."""
    return "\n".join(markup_line(line) for line in doc.lines)


def _esc(txt):
    """Escape literal text for Textual's markup parser. Only `\\` and `[` are
    special; a bare `[` (e.g. the `[` of an htop meter) must be backslashed or it
    leaks the surrounding tags — rich's own `escape` leaves non-tag `[` alone and
    isn't enough for Textual 8's stricter parser, so we do it ourselves."""
    return txt.replace("\\", "\\\\").replace("[", "\\[")


def markup_line(line):
    """One line of spans → a markup string (the list widget reuses this for its
    row labels, which are single lines, not whole Docs)."""
    buf = []
    for style, txt in line:
        tag = _MARKUP.get(style)
        esc = _esc(txt)
        buf.append(f"[{tag}]{esc}[/]" if tag else esc)
    return "".join(buf)
