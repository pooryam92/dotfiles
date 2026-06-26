"""browse — the Textual two-pane browser.

This is the only Textual-specific file in the package: a list on the left, a
scrollable detail pane on the right, vim keys to move within either (j/k/g/G) and
across them (l/h), and an optional `/` search box. It consumes Docs via
render_markup and knows nothing about what the tools mean — so a different TUI
framework would replace this file alone. Textual is imported inside browse() so
importing the package (for Doc/render_ansi) costs nothing.
"""

import os

from .doc import Doc
from .render import markup_line, render_markup


class Item:
    """One row in the left list. `label` is a span-list (or a bare str) shown in
    the list; `render` is a zero-arg callable returning the Doc for the detail
    pane when the row is highlighted."""

    def __init__(self, label, render):
        self.label = [("text", label)] if isinstance(label, str) else label
        self.render = render


def browse(items, *, title="", subtitle="", search=None, list_width=30,
           smoke_env=None, shot_env=None):
    """Run the two-pane TUI over `items`.

    items      list[Item] — left list + per-row detail Doc
    title/subtitle  header text (subtitle doubles as the key hint line)
    search     optional callable(query:str) -> Doc; when given, `/` opens a
               filter box and its Doc replaces the detail pane live
    list_width left-column width in cells
    smoke_env  if set and that env var is truthy, run a headless self-test
               (move, read, search, quit) instead of a live app
    shot_env   during a smoke run, if this env var is set, save an SVG frame to
               the path it holds
    """
    from rich.markup import escape as _escape
    from textual.app import App, ComposeResult
    from textual.binding import Binding
    from textual.containers import Horizontal, VerticalScroll
    from textual.widgets import Footer, Header, Input, ListItem, ListView, Static

    # Vim navigation lives on the widgets so the keys do the right thing for
    # whichever pane is focused: the list moves a cursor, the pane scrolls.
    class VimListView(ListView):
        BINDINGS = [
            Binding("j", "cursor_down", show=False),
            Binding("k", "cursor_up", show=False),
            Binding("g", "top", show=False),
            Binding("G", "bottom", show=False),
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
            Binding("j", "scroll_down", show=False),
            Binding("k", "scroll_up", show=False),
            Binding("g", "scroll_home", show=False),
            Binding("G", "scroll_end", show=False),
            Binding("h", "app.focus_list", show=False),
        ]

    bindings = [
        Binding("q", "quit", "quit"),
        Binding("l", "focus_detail", "read"),
        Binding("escape", "back", "back"),
    ]
    if search is not None:
        bindings.insert(1, Binding("slash", "search", "search"))

    class BrowseApp(App):
        # Colours come from the tokyo-night theme's variables ($secondary, $panel,
        # …) so the chrome matches WezTerm with no hardcoded hexes; list_width is
        # the only per-tool knob, woven in here.
        CSS = f"""
        Screen {{ background: $background; color: $foreground; }}

        #list {{ width: {list_width}; border-right: solid $panel; }}
        #list > ListItem {{ padding: 0 1; }}
        #list > ListItem.-highlight {{ background: $boost; }}
        #list:focus > ListItem.-highlight {{ background: $secondary 25%; text-style: bold; }}

        #detailbox {{ width: 1fr; padding: 0 1; }}
        #detailbox:focus {{ border-left: solid $secondary; }}

        #search {{ display: none; dock: bottom; background: $surface; border: tall $secondary; }}
        #search.on {{ display: block; }}
        #search > .input--placeholder {{ color: $text-disabled; }}
        """
        BINDINGS = bindings

        def compose(self) -> ComposeResult:
            yield Header(show_clock=False)
            rows = []
            for i, it in enumerate(items):
                li = ListItem(Static(markup_line(it.label, _escape)))
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
            self.query_one("#list", VimListView).focus()

        def _show(self, doc):
            self.query_one("#detail", Static).update(render_markup(doc))
            self.query_one("#detailbox", VimScroll).scroll_home(animate=False)

        def _show_item(self, item):
            if item is not None and getattr(item, "idx", None) is not None:
                self._show(items[item.idx].render())

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
            self._show(search(event.value) if event.value else Doc())

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
