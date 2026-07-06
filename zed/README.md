# Zed

[Zed](https://zed.dev) is a fast, GPU-accelerated GUI code editor. In this repo
it's the **graphical** counterpart to the terminal Neovim setup: same modal
Vim editing, same font, with its own theme (JetBrains Islands Dark — the one
exception to the repo's Tokyo Night theme) — so reaching for a mouse-driven
editor doesn't mean leaving the keyboard-first workflow behind (goals #1, #3).

- Docs: <https://zed.dev/docs/configuring-zed> · full settings list:
  <https://zed.dev/docs/reference/all-settings> · keymaps:
  <https://zed.dev/docs/key-bindings>
- Your config: `zed/settings.json` + `zed/keymap.json`

**The configs are the documentation** — both files are short JSONC (comments
allowed) with the why inline: `settings.json` covers Vim mode, the theme
extension, fonts, and format-on-save; `keymap.json` closes the small gaps
between Zed's vim defaults and the Neovim/IdeaVim configs — the bare
`Ctrl+h/j/k/l` split navigation, plus the `gi` (implementation) / `gr` (usages)
code-navigation keys IdeaVim spells lowercase. Zed applies edits the instant you
save — no reload step.

---

## How it's wired in this repo

Both files are linked by the main installers (`install.sh` / `install.ps1`):

| Repo file            | Linux target                  | Windows target                |
| -------------------- | ----------------------------- | ----------------------------- |
| `zed/settings.json`  | `~/.config/zed/settings.json` | `%APPDATA%\Zed\settings.json` |
| `zed/keymap.json`    | `~/.config/zed/keymap.json`   | `%APPDATA%\Zed\keymap.json`   |

> Note the case: Zed's config dir is lowercase `zed` on Linux (XDG) but
> capitalized `Zed` on Windows (Roaming `%APPDATA%`).

**Installing Zed itself is opt-in and lives in its own script** — Zed is a GUI
app, so it stays out of the main installers' terminal/CLI flow (the same way
the niri session does). Run once: `./zed/install-zed.sh` (Linux) /
`.\zed\install-zed.ps1` (Windows). Zed self-updates from there. The config
links above are made by the main installers regardless of whether Zed itself is
installed.

---

## Working with the config

- **Toggle Vim mode at runtime:** command palette (`Ctrl-Shift-P`) →
  "workspace: toggle vim mode" — no file edit needed. Vim-specific options live
  under a `"vim"` settings block: <https://zed.dev/docs/vim>.
- **Discover an action name** for a keybinding: open the command palette, find
  the command, and its action id is shown — paste that as the binding value.
- **Map-type settings merge over defaults** (e.g. `auto_install_extensions`),
  and the keymap is **additive** — you only spell out what you're changing;
  Zed's built-in bindings stay.

---

## Next upgrade

This config keeps keymaps minimal on purpose. The natural next step — if you
want Zed to feel like the IdeaVim setup — is to port the **`<leader>`
namespace** (Space-prefixed maps grouped by area: `f` files, `g` goto/git, `c`
code, …) into `keymap.json` using Zed's Vim leader support. See the
[IdeaVim guide](../intellij/README.md) for the namespace to mirror and
<https://zed.dev/docs/vim> for how Zed expresses multi-key Vim bindings.
