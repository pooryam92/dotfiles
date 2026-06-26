"""cheat — a learn-the-terminal sheet (Python + Textual).

Split by concern so each file reads on its own:

  data.py     load the two TSVs into (cats, rows); category lookup helpers
  content.py  turn that data into framework-neutral `tui.Doc`s (the screens)
  cli.py      argument handling, plain-text output, and launching the TUI
  cheat.py    the thin entry point the installer symlinks to ~/.config/cheat.py

Reads the SAME two data files as the original cheat.lua so the two stay
interchangeable:

  cheat.tsv        category<TAB>key<TAB>action<TAB>tip   (the entries)
  cheat-index.tsv  category<TAB>blurb                    (row order = learning order)

The two-pane browser, vim keys and palette live in the shared `tui` package; this
package only describes content.
"""

__version__ = "1.1.0"
