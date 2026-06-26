"""tui — a tiny reusable two-pane terminal browser for the dotfiles tool suite.

`cheat` and `keymap` are the same shape: a list on the left, a scrollable detail
pane on the right, vim keys to move within and across them. This package owns
that shell so the tools describe only *content*, never the framework.

The seam is a framework-neutral document model, split by concern:

  doc.py     the content model — Span builders + `Doc` + `hl` (no deps)
  render.py  Doc → a concrete face — `render_ansi` (plain) / `render_markup`
  browse.py  the Textual two-pane app — `browse()` + `Item` (the only TUI file)

Tools build Docs and call `browse()` / `render_ansi`; they never import Textual
or emit markup. Swapping the TUI underneath touches browse.py (and a renderer in
render.py) — nothing in the tools. This `__init__` is the public surface:

    import tui
    d = tui.Doc().line(tui.title("hi"), tui.dim("there"))
    tui.browse([tui.Item("row", lambda: d)], title="demo")
    print(tui.render_ansi(d))
"""

from .browse import Item, browse
from .doc import Doc, accent, dim, hl, key, match, text, title
from .render import render_ansi, render_markup

__all__ = [
    "Doc", "Item", "accent", "browse", "dim", "hl", "key", "match",
    "render_ansi", "render_markup", "text", "title",
]
