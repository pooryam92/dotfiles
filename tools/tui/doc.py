"""doc — the framework-neutral content model the tools speak.

A `Doc` is a list of lines; a line is a list of `Span`s; a Span is
`(style, text)` where `style` is a SEMANTIC name (title/key/text/dim/accent/
match), never a colour or markup syntax. The tools build Docs; `render.py` maps
the styles to a palette for whichever face is in use (ANSI plain text or the
Textual pane). Nothing here imports Textual or rich — that's the whole point.
"""

# The styles a renderer must know how to colour. Kept here so render.py and any
# future renderer can assert they cover the set.
STYLES = ("title", "key", "text", "dim", "accent", "match")


def title(s):  return ("title", s)   # section heading       (blue, bold)
def key(s):    return ("key", s)     # a key / name / label  (cyan)
def text(s):   return ("text", s)    # ordinary body text    (default fg)
def dim(s):    return ("dim", s)     # secondary / hints      (grey)
def accent(s): return ("accent", s)  # bars, emphasis         (yellow)
def match(s):  return ("match", s)   # a search hit           (yellow, bold)


def hl(s, query, base="text"):
    """Split `s` into spans, tagging case-insensitive matches of `query` as
    `match` and the rest as `base`. Returns a list of spans (splice into a line
    with `*hl(...)`). With no query, one `base` span — so callers stay uniform.
    """
    if not query:
        return [(base, s)]
    low, ql, out, i = s.lower(), query.lower(), [], 0
    while (j := low.find(ql, i)) >= 0:
        if j > i:
            out.append((base, s[i:j]))
        out.append(("match", s[j:j + len(query)]))
        i = j + len(query)
    if i < len(s):
        out.append((base, s[i:]))
    return out or [(base, s)]


class Doc:
    """A growable list of lines, each a list of spans. Builders return self so
    calls chain; `line()` flattens any span-lists handed to it (e.g. `*hl(...)`)."""

    def __init__(self):
        self.lines: list[list] = []

    def line(self, *spans):
        flat = []
        for s in spans:
            flat.extend(s) if isinstance(s, list) else flat.append(s)
        self.lines.append(flat)
        return self

    def blank(self):
        self.lines.append([])
        return self

    def extend(self, other):
        """Append another Doc's lines — lets plain mode concatenate sections."""
        self.lines.extend(other.lines)
        return self
