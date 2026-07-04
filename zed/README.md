# Zed

[Zed](https://zed.dev) is a fast, GPU-accelerated GUI code editor. In this repo
it's the **graphical** counterpart to the terminal Neovim setup: same modal
Vim editing, same font, with its own theme (JetBrains Islands Dark — the one
exception to the repo's Tokyo Night theme) — so reaching for a mouse-driven
editor doesn't mean leaving the keyboard-first workflow behind (goal #1, goal #3).

It's configured with plain JSON (JSONC, so `//` comments and trailing commas are
fine), and Zed applies edits the instant you save — no reload step.

- Docs: <https://zed.dev/docs/configuring-zed> · full key list:
  <https://zed.dev/docs/reference/all-settings>
- Your config: `zed/settings.json` + `zed/keymap.json`

This config is **minimal & focused** (goal #2): a handful of settings that align
Zed with the rest of the stack, and one keymap block for split-navigation parity.
Everything else is left at Zed's sensible defaults.

---

## How it's wired in this repo

Two files are linked into Zed's config directory by the main installers
(`install.sh` / `install.ps1`):

| Repo file            | Linux target                | Windows target              |
| -------------------- | --------------------------- | --------------------------- |
| `zed/settings.json`  | `~/.config/zed/settings.json` | `%APPDATA%\Zed\settings.json` |
| `zed/keymap.json`    | `~/.config/zed/keymap.json`   | `%APPDATA%\Zed\keymap.json`   |

> Note the case: Zed's config dir is lowercase `zed` on Linux (XDG) but
> capitalized `Zed` on Windows (Roaming `%APPDATA%`).

**Installing Zed itself is opt-in and lives in its own script** — Zed is a GUI
app, so it stays out of the main installers' terminal/CLI flow (the same way the
niri session does). Run it once:

```bash
./zed/install-zed.sh      # Linux  — curl … zed.dev/install.sh
```
```powershell
.\zed\install-zed.ps1     # Windows — scoop install zed (extras bucket)
```

Zed self-updates from there, so the update scripts don't track it. The config
links above are handled by the main installers regardless of whether Zed itself
is installed.

---

## settings.json

```jsonc
"vim_mode": true,                 // modal editing, like Neovim / IdeaVim
"theme": "JetBrains Islands Dark",                   // JetBrains "Islands" dark variant
"auto_install_extensions": { "jetbrains-themes": true },  // pull the theme on first launch
"buffer_font_family": "JetBrainsMono Nerd Font",
"buffer_font_size": 14,
"format_on_save": "off"           // matches the Neovim default
```

A few things worth knowing:

- **Theme.** Zed ships no JetBrains theme built-in, so `auto_install_extensions`
  fetches the [`jetbrains-themes`](https://zed.dev/extensions/jetbrains-themes)
  extension on first launch. Unlike the terminal tools (which follow the
  terminal's palette via named colors), Zed is a GUI app with its own theme
  engine, so it names the theme outright. Zed is the one tool that doesn't use
  the repo's Tokyo Night theme — it keeps JetBrains Islands Dark. Other variants
  the extension provides: `"JetBrains Islands Light"`, `"JetBrains Dark"`,
  `"JetBrains Light"`.
- **Vim mode.** Toggle it at runtime from the command palette
  (`Ctrl-Shift-P` → "workspace: toggle vim mode") without editing the file.
  Vim-specific options live under a `"vim"` block — see
  <https://zed.dev/docs/vim>.
- **Map-type settings merge.** Object settings like `auto_install_extensions`
  merge *over* Zed's defaults, so listing `jetbrains-themes` doesn't disable Zed's
  default `html` extension — you only spell out what you're changing.

---

## keymap.json

Zed already binds Vim's `Ctrl-w h/j/k/l` to move between splits. This adds the
**bare** `Ctrl-h/j/k/l` form used by the Neovim and IdeaVim configs, so split
navigation is identical across all three editors:

```jsonc
{
  "context": "VimControl && !menu",   // any non-insert Vim mode, no popup open
  "bindings": {
    "ctrl-h": "workspace::ActivatePaneLeft",
    "ctrl-l": "workspace::ActivatePaneRight",
    "ctrl-j": "workspace::ActivatePaneDown",
    "ctrl-k": "workspace::ActivatePaneUp"
  }
}
```

`context` scopes a binding to a UI state (here, Vim's non-insert modes); see
<https://zed.dev/docs/key-bindings> for the full context grammar. The keymap is
**additive** — it layers on top of the defaults rather than replacing them.

---

## Common tweaks

| Want to…                  | Edit                                                       |
| ------------------------- | ---------------------------------------------------------- |
| Change font / size        | `buffer_font_family` / `buffer_font_size`                  |
| Switch theme              | `"theme"` → any installed theme name (add it to `auto_install_extensions`) |
| Format on every save      | `"format_on_save": "on"` (add `formatter` per language)    |
| Add a keybinding          | a new block in `keymap.json` (find action names in palette)|
| Turn Vim off              | `"vim_mode": false`, or toggle from the command palette    |

**Discover an action name** for a keybinding: open the command palette
(`Ctrl-Shift-P`), find the command, and its action id is shown — paste that as
the binding value.

---

## Next upgrade

This config keeps keymaps minimal on purpose. The natural next step — if you want
Zed to feel like the IdeaVim setup — is to port the **`<leader>` namespace**
(Space-prefixed maps grouped by area: `f` files, `g` goto/git, `c` code, …) into
`keymap.json` using Zed's Vim leader support. See the
[IdeaVim guide](../intellij/README.md#the-leader-namespace) for the namespace to mirror and
<https://zed.dev/docs/vim> for how Zed expresses multi-key Vim bindings.
