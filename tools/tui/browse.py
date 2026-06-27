"""browse — the Textual two-pane browser.

This is the only Textual-specific file in the package: a list on the left, a
scrollable detail pane on the right, vim keys to move within either (j/k/g/G) and
across them (l/h), and an optional `/` search box. It consumes Docs via
render_markup and knows nothing about what the tools mean — so a different TUI
framework would replace this file alone. Textual is imported inside browse() so
importing the package (for Doc/render_ansi) costs nothing.
"""

import os

from .doc import Doc, bar
from .render import markup_line, render_markup


class Item:
    """One row in the left list. `label` is a span-list (or a bare str) shown in
    the list; `render` is a zero-arg callable returning the Doc for the detail
    pane when the row is highlighted; `title` is the plain text shown in the
    detail panel's border while this row is read (defaults to the label text).
    `value` is an optional magnitude — when any item carries one, every row grows
    an htop-style bracket meter on the right, sized against the largest value."""

    def __init__(self, label, render, title=None, value=None):
        self.label = [("text", label)] if isinstance(label, str) else label
        self.render = render
        self.value = value
        self.title = title if title is not None else \
            "".join(t for _, t in self.label).strip()


def _meter_rows(items, inner_w):
    """Pre-render each item's row label as a span-list, right-aligning an htop
    bracket meter when values are present. Returns a list of span-lists (one per
    item) so `compose` just maps them to markup. Without values, rows are the
    bare labels — so meter-less tools (keymap's view list) look exactly as before.

    Layout per row:  ``label …gutter… [|||||   ] value`` — all rows share one
    bar width and one value column so the meters line up into a clean chart."""
    if not any(it.value is not None for it in items):
        return [it.label for it in items]

    vmax = max((it.value for it in items if it.value is not None), default=0)
    vw = len(str(vmax))                       # value column width (right-aligned)
    label_w = max(sum(len(t) for _, t in it.label) for it in items)
    # inner_w = label_w + gutter(≥1) + "[" bars "]"(bar_w+2) + " " + value(vw)
    bar_w = max(4, min(16, inner_w - label_w - 1 - 2 - 1 - vw))

    rows = []
    for it in items:
        if it.value is None:
            rows.append(it.label)
            continue
        lw = sum(len(t) for _, t in it.label)
        meter = bar(it.value, vmax, bar_w) + [("dim", " " + str(it.value).rjust(vw))]
        meter_w = bar_w + 2 + 1 + vw
        gutter = max(1, inner_w - lw - meter_w)
        rows.append(it.label + [("text", " " * gutter)] + meter)
    return rows


def browse(items, *, title="", subtitle="", search=None, list_width=30,
           list_title="list", smoke_env=None, shot_env=None):
    """Run the two-pane TUI over `items`.

    Chrome mirrors canonical Linux TUIs (lazygit/k9s): every pane is a titled,
    rounded box; the focused pane's border lights up; the detail box's border
    names what you're reading; a context-aware keybar sits at the bottom.

    items      list[Item] — left list + per-row detail Doc
    title/subtitle  header text shown top-left (subtitle = context, not keys —
               the keys live in the bottom bar)
    search     optional callable(query:str) -> Doc; when given, `/` opens a
               filter box and its Doc replaces the detail pane live
    list_width left-column width in cells
    list_title label drawn into the left pane's border
    smoke_env  if set and that env var is truthy, run a headless self-test
               (move, read, search, quit) instead of a live app
    shot_env   during a smoke run, if this env var is set, save an SVG frame to
               the path it holds
    """
    from textual.app import App, ComposeResult
    from textual.binding import Binding
    from textual.containers import Horizontal, VerticalScroll
    from textual.widgets import Footer, Header, Input, ListItem, ListView, Static

    # Vim navigation lives on the widgets so the keys do the right thing for
    # whichever pane is focused: the list moves a cursor, the pane scrolls.
    class VimListView(ListView):
        # show=True so the focused pane contributes its keys to the bottom bar,
        # giving the context-aware keybar that lazygit/k9s have.
        BINDINGS = [
            Binding("j", "cursor_down", "down"),
            Binding("k", "cursor_up", "up"),
            Binding("g", "top", show=False),
            Binding("G", "bottom", show=False),
            Binding("l", "app.focus_detail", "read"),
        ]

        def action_top(self):
            if self.children:
                self.index = 0

        def action_bottom(self):
            if self.children:
                self.index = len(self.children) - 1

    class VimScroll(VerticalScroll):
        can_focus = True
        BINDINGS = [
            Binding("j", "scroll_down", "down"),
            Binding("k", "scroll_up", "up"),
            Binding("g", "scroll_home", show=False),
            Binding("G", "scroll_end", show=False),
            Binding("h", "app.focus_list", "back"),
        ]

    bindings = [
        Binding("q", "quit", "quit"),
        Binding("escape", "back", show=False),
        Binding("1", "focus_list", show=False),    # lazygit-style pane jump
        Binding("2", "focus_detail", show=False),
    ]
    if search is not None:
        bindings.insert(1, Binding("slash", "search", "filter"))

    class BrowseApp(App):
        # Colours come from the tokyo-night theme's variables ($secondary, $panel,
        # …) so the chrome matches WezTerm with no hardcoded hexes; list_width is
        # the only per-tool knob, woven in here. The look mirrors lazygit/k9s:
        # every pane is a rounded titled box, and the focused one's border (and
        # title) light up in the accent so you always know where you are.
        CSS = f"""
        Screen {{ background: $background; color: $foreground; }}

        #list {{
            width: {list_width};
            border: round $panel;
            border-title-color: $text-muted;
            padding: 0 1;
        }}
        #list:focus {{ border: round $secondary; border-title-color: $secondary; }}
        #list > ListItem {{ padding: 0 1; }}
        #list > ListItem.-highlight {{ background: $boost; }}
        #list:focus > ListItem.-highlight {{ background: $secondary 25%; text-style: bold; }}

        #detailbox {{
            width: 1fr;
            border: round $panel;
            border-title-color: $text-muted;
            padding: 0 1;
        }}
        #detailbox:focus {{ border: round $secondary; border-title-color: $secondary; }}

        #search {{ display: none; dock: bottom; background: $surface; border: round $secondary; }}
        #search.on {{ display: block; }}
        #search > .input--placeholder {{ color: $text-disabled; }}
        """
        BINDINGS = bindings

        def compose(self) -> ComposeResult:
            yield Header(show_clock=False)
            # Usable text width = list_width − border(2) − #list padding(2) −
            # ListItem padding(2). Getting this right keeps meter rows on one line.
            row_labels = _meter_rows(items, list_width - 6)
            rows = []
            for i, label in enumerate(row_labels):
                li = ListItem(Static(markup_line(label)))
                li.idx = i
                rows.append(li)
            with Horizontal():
                yield VimListView(*rows, id="list")
                with VimScroll(id="detailbox"):
                    yield Static(id="detail", expand=True)
            if search is not None:
                box = Input(placeholder="type to filter…", id="search")
                box.border_title = "search"
                yield box
            yield Footer()

        def on_mount(self):
            self.theme = "tokyo-night"  # match WezTerm / the rest of the setup
            self.title = title
            self.sub_title = subtitle
            self.query_one("#list", VimListView).border_title = list_title
            self.query_one("#list", VimListView).focus()

        def _show(self, doc, panel_title=None):
            self.query_one("#detail", Static).update(render_markup(doc))
            self.query_one("#detailbox", VimScroll).border_title = panel_title or ""
            self.query_one("#detailbox", VimScroll).scroll_home(animate=False)

        def _show_item(self, item):
            if item is not None and getattr(item, "idx", None) is not None:
                it = items[item.idx]
                self._show(it.render(), it.title)

        def on_list_view_highlighted(self, event):
            self._show_item(event.item)

        def on_list_view_selected(self, event):
            # Enter on a row → jump into the detail pane to scroll it (j/k).
            self.action_focus_detail()

        def action_focus_detail(self):
            self.query_one("#detailbox", VimScroll).focus()

        def action_focus_list(self):
            self.query_one("#list", VimListView).focus()

        # --- search (only wired when a search function was supplied) ---------
        def action_search(self):
            box = self.query_one("#search", Input)
            box.add_class("on")
            box.focus()

        def on_input_changed(self, event):
            q = event.value
            self._show(search(q) if q else Doc(), f"search: {q}" if q else None)

        def action_back(self):
            if search is not None:
                box = self.query_one("#search", Input)
                if box.has_class("on"):
                    box.remove_class("on")
                    box.value = ""
                    lv = self.query_one("#list", VimListView)
                    lv.focus()
                    self._show_item(lv.highlighted_child)
                    return
            self.query_one("#list", VimListView).focus()

    app = BrowseApp()
    if smoke_env and os.environ.get(smoke_env):  # headless self-test
        async def _pilot(p):
            await p.pause()
            if shot_env and os.environ.get(shot_env):
                app.save_screenshot(os.environ[shot_env])
            await p.press("j", "j", "k")   # vim move in the list
            await p.press("g", "G")         # first / last row
            await p.press("l")              # into the detail pane
            await p.press("j", "k")         # vim-scroll it
            await p.press("h")              # back to the list
            if search is not None:
                await p.press("slash", "p", "a", "n", "e")  # exercise search
                await p.pause()
                await p.press("escape")     # close it
                await p.pause()
            app.exit()
        app.run(headless=True, auto_pilot=_pilot)
        return
    app.run()
