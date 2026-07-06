# IdeaVim

[IdeaVim](https://github.com/JetBrains/ideavim) is the **Vim emulation plugin
for JetBrains IDEs** (IntelliJ, PyCharm, WebStorm, Rider, …). It gives you Vim
motions, modes, and mappings inside the IDE editor, while letting you bind keys
to the IDE's own *actions* (refactor, goto, run, git, tool windows). The config
file is `~/.ideavimrc` and uses Vimscript syntax.

The key idea is `<Action>(...)` — that's how a Vim mapping triggers a native
JetBrains command. You find an action's ID with the **IdeaVim: track action
Ids** toggle (or `:action VimFindActionIdAction`): enable it, run any IDE
command, and IdeaVim shows the ID to use.

- Docs: <https://github.com/JetBrains/ideavim/blob/master/README.md>
- Your config: `intellij/.ideavimrc` → symlinked to `~/.ideavimrc`

**The config is the documentation** — `.ideavimrc` is ~130 lines organized by
leader prefix, with the namespace summarized in its header comment. Every
custom map lives under a themed prefix (`<leader>` is **Space**):

| Prefix | Theme                     |
| ------ | ------------------------- |
| `e`    | Explorer / Project        |
| `f`    | Files                     |
| `g`    | Goto (bare `g`) / Git     |
| `c`    | Code / Refactor           |
| `m`    | Make / Run / Debug        |
| `t`    | Tests / Terminal          |
| `s`    | Settings / Search / Symbols |
| `a`    | AI                        |
| `v`    | Vim Coach                 |

---

## Day-to-day usage

- **Edit then reload:** open with `<leader>fc`, change something, save, then
  `<leader>sr` to apply without restarting the IDE.
- **Discover a binding target:** enable **IdeaVim: track action Ids**, run the
  IDE command via menu/shortcut, note the ID, then map it with `<Action>(ID)`.
- **Verify an action exists:** if a map "does nothing," the action ID is wrong —
  most failures are typos in the ID (this is exactly what bit the old reload
  map: `deaVim.…` instead of `IdeaVim.…`).
- **Resolve a key clash** (IdeaVim vs IDE shortcut): the IDE pops a handler
  picker; set the default in **Settings → Editor → Vim**.
- **Turn Vim off temporarily:** the **IdeaVim** entry in Tools (or the
  status-bar widget).
- **Vim Coach** (`<leader>vt`) needs the *Vim Coach* plugin from the JetBrains
  Marketplace; easymotion (commented out in the config) needs *AceJump*.

---

## Common tweaks

**Add an emulated plugin** — `set <name>` near the others (e.g. uncomment
`easymotion`/`multiple-cursors`, or add `set ReplaceWithRegister`, `set argtextobj`).

**Map a new IDE action** (find the ID first via tracking):
```vim
nmap <leader>gl <Action>(Git.Log)
```

**Syntax notes:**
- Escape a literal `|` in a mapping as `\|` (see `<leader>\|`).
- Use `<Action>(ID)` for IDE actions; use `:cmd<CR>` only for real ex-commands
  (`:e`, `:nohlsearch`, `:NERDTreeToggle`).
- `nmap` is recursive; `nnoremap`/`noremap` aren't — prefer the `noremap` forms
  unless you need recursion. (Most `<Action>(...)` maps are written `nmap` here
  because there's nothing to recurse into.)

---

## Cheatsheet

| Keys              | Action                          |
| ----------------- | ------------------------------- |
| `<Space>`         | leader                          |
| `<leader><space>` | Go to file                      |
| `<leader>/`       | Find in path · `<leader>nh` clear hl |
| `<leader>e`       | Toggle file tree                |
| `Ctrl+h/j/k/l`    | Move between splits             |
| `<leader>-` / `\|`| Split horizontal / vertical     |
| `Alt+j` / `Alt+k` | Move line down / up             |
| `gd gi gy` / `gr` | Goto decl/impl/type · usages    |
| `gcc` / `cs"'`    | Comment line · change surround  |
| `<leader>cr/ca`   | Rename · quick-fix              |
| `<leader>cf/co`   | Reformat · optimize imports     |
| `<leader>mr/md`   | Run · Debug                     |
| `<leader>mb/ms`   | Breakpoint · Stop               |
| `<leader>tr/tf`   | Run tests · rerun failed        |
| `<leader>tt`      | Terminal                        |
| `<leader>g…`      | Git (s/b/c/B/h/p/P)             |
| `<leader>s…`      | Settings/action/symbol/class    |
| `<leader>sr`      | Reload `.ideavimrc`             |
| `<leader>a`       | Ask AI Assistant                |
| `<leader>vt`      | Vim Coach — show tip            |
