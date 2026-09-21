# VS Code

[VS Code](https://code.visualstudio.com) is the second **graphical** editor in
this repo, alongside [Zed](../zed/README.md). Same modal Vim editing, same font
(goal #1). The theme is **Dark Modern** — VS Code's own built-in default, so it
needs no extension and can't fail on a fresh machine (goal #2). It's deliberately
not the repo's Tokyo Night: that palette's Night variant reads too dark in a full
IDE chrome, and both Tokyo Night Storm and JetBrains Islands Dark were tried here
and dropped. Where Zed is the fast, minimal one, VS Code is the one with the
extension ecosystem behind it, and the one that renders Markdown properly.

- Docs: <https://code.visualstudio.com/docs/getstarted/settings> · keybindings:
  <https://code.visualstudio.com/docs/getstarted/keybindings> · Vim extension:
  <https://github.com/VSCodeVim/Vim#-settings>
- Your config: `vscode/settings.json` + `vscode/keybindings.json` +
  `vscode/extensions.txt`

**The configs are the documentation** — both files are JSONC (comments allowed)
with the why inline. They list only what DIFFERS from the defaults, so they read
as a changelog rather than a full settings dump.

---

## The one thing that will surprise you

**`.md` files open rendered, not as source.** That's deliberate — it's what
Markdown is for, and VS Code's preview is built in (no extension). But the first
time you open a README expecting to type in it, you'll hit a wall.

| Keys | What it does |
| ---- | ------------ |
| `Ctrl+Shift+V` | **Toggle** rendered ⇄ source — works in both directions |
| `Ctrl+K V` | Open a preview **beside** the source (best mode for writing) |

The toggle is half default, half ours: VS Code binds `Ctrl+Shift+V` to
`markdown.showPreview` (source → rendered), and `keybindings.json` adds
`markdown.showSource` for the trip back. The reason that binding lives in
`keybindings.json` and not with the Vim maps in `settings.json`: the preview pane
isn't an editable buffer, so Vim mode isn't running there and a Vim mapping could
never fire.

To turn the behaviour off, delete the `"*.md"` line from
`workbench.editorAssociations` in `settings.json`. To keep it for READMEs only,
narrow the glob to `"**/README.md"`.

---

## Keys — matched to the other editors

Vim mode comes from the **VSCodeVim** extension; `settings.json` configures it.
Leader is `<Space>`, as in every other config here.

### Bare keys

| Keys | Action | Same as |
| ---- | ------ | ------- |
| `Ctrl+h/j/k/l` | Move between editor groups | nvim, IdeaVim, Zed |
| `gd` / `gD` | Definition / declaration | IdeaVim `gd` / `gD` |
| `gi` / `gy` | Implementation / type definition | IdeaVim `gi` / `gy` |
| `gr` | Find all references (side panel) | IdeaVim `gr` (FindUsages) |
| `ga` / `gR` | Quick fix / rename | IdeaVim `ga` / `gR` |
| `Alt+j` / `Alt+k` | Move current line down / up | IdeaVim `<A-j>`/`<A-k>` |
| `<leader><Space>` / `<leader>/` | Go to file / find in files | IdeaVim |
| `<leader>e` | Focus the file explorer | IdeaVim (NERDTree) |
| `<leader>-` / `<leader>\|` | Split down / right | nvim, IdeaVim |
| `<leader>nh` | Clear search highlight | nvim `<Esc>`, IdeaVim |

### The `<leader>` namespace — same letters as IdeaVim

Grouped by area, so **one map covers JetBrains and VS Code**. `<Space>` then:

| Group | Keys |
| ----- | ---- |
| **`f`** Files | `fr` recent files · `fn` new file · `fc` edit live settings.json |
| **`g`** Git | `gs` status/staging · `gb` switch branch · `gc` commit · `gp`/`gP` pull/**push** · `gh` file history (Timeline) · `gB` toggle inline blame · `gw`/`gW` switch **w**orktree here/new window · `gn` new worktree |
| **`c`** Code | `cr` rename · `ca` quick fix · `cf` format document · `co` organise imports |
| **`m`** Run/Debug | `mr` run · `md` run **with** debugger · `ms` stop · `mb` toggle breakpoint · `mc` pick run config |
| **`t`** Test/Term | `tr` run tests in file · `tf` rerun failed · `tl` rerun last · `tt` toggle terminal |
| **`s`** Settings | `so` Settings UI · `sa` command palette · `ss` symbol in project · `sf` symbol in **f**ile |
| **`a`** AI | `a` open Claude Code (goal #4) — a single key, as in `.ideavimrc` |

Bare `<leader>g` is git; bare `g` is goto — two separate namespaces, same as
`.ideavimrc`. Four keys are **not** from IdeaVim, because VS Code has something
JetBrains doesn't: `<leader>sf` (VS Code splits project symbols from in-file
symbols, and the in-file picker was too useful to leave unbound) and the three
worktree keys `gw`/`gW`/`gn` — see below.

**There is no which-key popup for VSCodeVim**, so this table *is* the discovery
mechanism until the groups are muscle memory. Start with one group.

Four IdeaVim maps have no VS Code equivalent and are deliberately absent:
`<leader>sr` (reload vimrc — VS Code applies settings live), `<leader>sc`
(GotoClass — no class-only picker; `<leader>ss` searches all symbols),
`<leader>st` (Vim Coach plugin), `<leader>ep` (Project tool window — that *is*
the explorer here).

Non-Vim settings worth knowing: `y`/`p` use the **system clipboard**,
`hlsearch` is on, and yanks flash — all three differ from VSCodeVim's defaults
and match `.ideavimrc` / `nvim/init.lua`. On save, trailing whitespace is
trimmed and a final newline added — **except in Markdown**, where two trailing
spaces are a hard line break.

### Why `Alt+j`/`Alt+k` live in `keybindings.json`, not with the Vim maps

Because a Vim mapping for them would never fire. VSCodeVim only receives the
keys it registers in its own `package.json` — 75 of them, and **not one is
`alt+<letter>`**. VS Code routes `alt+j` through its own keybinding table and
the extension never sees it. So Alt chords go in `keybindings.json`; everything
else goes in `settings.json`.

That created one collision worth knowing about: the Claude Code extension claims
plain `alt+k` for "insert @-mention". User keybindings beat extension ones, so
move-line-up wins and **@-mention moved to `Alt+Shift+K`**.

---

## Worktrees — parallel branches, one click

A **worktree** is a second checkout of the same repo in another folder, on
another branch, sharing one `.git`. It replaces the stash-and-switch dance: a
code review, a hotfix, or a `claude --worktree` session gets its own folder and
its own VS Code window while your real work stays exactly where you left it.
That's goal #1 (fewer interruptions) meeting goal #4 (an AI session that can't
collide with what you're editing).

**VS Code's own git extension ships the whole feature** — no extension to
install, nothing to fall back from on a fresh machine (goal #2), identical on
both OSes (goal #3). It's just shipped **off**: `settings.json` sets
`"git.detectWorktrees": true`, which is the entire switch. With it on, worktrees
appear in Source Control as their own repositories, with a **Worktrees** submenu
in the panel's title bar.

| Keys | Command | What it does |
| ---- | ------- | ------------ |
| `<leader>gn` | `git.createWorktree` | Create a worktree (prompts for branch + location) |
| `<leader>gw` | `git.openWorktree` | Switch to one **in this window** |
| `<leader>gW` | `git.openWorktreeInNewWindow` | Switch to one in a **new window** |
| — | `git.deleteWorktree` | Palette only — `Git: Delete Worktree...` |

None of these has a default keybinding, which is why they're bound above.

**Put worktrees beside the repo, not inside it** — `~/code/myrepo/` and
`~/code/myrepo.wt/feat-x/`. Nesting them under the repo means every window's
file watcher and `<leader>/` search walk all of them, and it used to make the
shell prompt display the *main* repo's branch while you stood in a worktree
(fixed — see below — but sibling layout is still the right default).

**`git.worktreeIncludeFiles` is the setting that makes a new worktree usable.**
`git worktree add` materialises only *tracked* files, so a fresh worktree has no
`.env` and won't run. That setting lists gitignored globs to copy in; it's set to
`[".env", ".env.local"]`. Don't add `node_modules`/`.venv` — reinstall those in
the worktree instead of copying them.

**The shell prompt follows you into a worktree.** Inside one, `.git` is a *file*
(`gitdir: …/.git/worktrees/<name>`), not a directory — both prompts now resolve
it, so `zsh/.zshrc` and `pwsh/profile.ps1` show the worktree's branch instead of
nothing (or, nested, the wrong one). Still zero subprocesses per draw.

Two things worth knowing once: a branch can only be checked out in **one**
worktree at a time (that's the safety feature, not a limitation), and deleting
the folder isn't enough — use `git worktree remove <path>`, or `git worktree
prune` to clean up after the fact.

---

## How it's wired in this repo

Both files are placed by the main installers (`install.sh` / `install.ps1`) — but
by **different strategies**, which matters:

| Repo file                  | How            | Linux target                          | Windows target                         |
| -------------------------- | -------------- | ------------------------------------- | -------------------------------------- |
| `vscode/settings.json`     | **copied**     | `~/.config/Code/User/settings.json`   | `%APPDATA%\Code\User\settings.json`    |
| `vscode/keybindings.json`  | symlinked      | `~/.config/Code/User/keybindings.json`| `%APPDATA%\Code\User\keybindings.json` |

> Note the capital `Code` on both — VS Code doesn't follow the XDG lowercase
> convention on Linux the way Zed does.

**Why `settings.json` is a copy and not a live symlink** — the one place this
editor breaks the repo's usual pattern. VS Code rewrites user `settings.json`
every time you change something through its UI, and user settings is where
*machine-specific and work* state collects: mssql connection profiles (server
hostnames, usernames), Python interpreter paths, Copilot toggles. **This repo is
public**, so a symlink would quietly push all of that into it. A copy seeds the
defaults and then lets the live file diverge locally — the same strategy, for the
same reason, as [`claude/settings.json`](../claude/README.md).

Two consequences worth internalising:

- **Editing `vscode/settings.json` does not affect a running VS Code.** Re-run
  the main installer to re-copy it — which **backs up and replaces** your live
  settings (to `settings.json.bak.<timestamp>`), so local additions stop applying
  until you merge them back out of the backup.
- **Keep machine- and job-specific settings out of this file.** Put them in the
  live file, or better in per-project `.vscode/settings.json`, which always wins
  over user settings.

`keybindings.json` stays a live symlink — it holds no machine state, and VS Code
only writes it when you deliberately change a keybinding.

**VS Code is part of the core install.** `install.sh` adds Microsoft's apt repo
and installs `code` (Linux); `install.ps1` installs it via winget, user scope, no
admin (Windows). Both then install the extensions and link the configs above.
`install.sh update` upgrades it with the other apt packages; on Windows it
self-updates.

**Extensions are data, not script.** Both installers read
[`vscode/extensions.txt`](extensions.txt) — one id per line, `#` comments
allowed — so adding an extension is one edit, in one file, and Windows and Linux
can't drift apart (goal #3). The list is deliberately short — two entries, since
the theme is built in and needs nothing installed:

| Extension | Why it's mandatory |
| --------- | ------------------ |
| `vscodevim.vim` | Vim mode; `settings.json` is 45 mappings of configuration for it |
| `anthropic.claude-code` | Claude Code in-editor: diffs, selection context, `@`-mentions (goal #4) |

Per-language tooling (Python, C#, SQL…) stays **off** this list on purpose —
it's machine- and job-specific, and this repo is public.

**Why winget on Windows, when the rest of the repo is scoop?** scoop's `vscode`
manifest runs VS Code in *portable* mode — settings go to
`<scoop>\persist\vscode\data\user-data\User\`, not `%APPDATA%\Code`. That path
isn't stable enough to name in `links.tsv`, and it would fork the config path
from Linux for no benefit. winget's user-scope install is equally admin-free and
uses the standard path. scoop stays the tool for the CLI stack.

**Updates:** VS Code self-updates on Windows. On **Linux** it's apt-managed via
the Microsoft repo the script adds, so it upgrades with a normal
`sudo apt-get upgrade` — `install.sh update` deliberately leaves it alone (that
command scopes itself to the packages `install.sh` owns).

---

## Working with the config

- **`settings.json` is copied, `keybindings.json` is linked** — see the section
  above for why, and for what that means when you edit either one. Both
  strategies are one word in the `type` column of
  [`setup/links.tsv`](../setup/links.tsv) (`copy` / `file`) if you want to change
  the trade-off.
- **Find a command id** for a binding: `Ctrl+Shift+P`, find the command, click
  the gear beside it — or open the keybindings UI (`Ctrl+K Ctrl+S`) and use its
  `{}` button to read the defaults as JSON.
- **Editing keys? Edit `settings.json`, not `keybindings.json`.** Vim mappings go
  under `vim.normalModeKeyBindingsNonRecursive`. `keybindings.json` is only for
  the two kinds of chord a Vim mapping can't express: ones that must work outside
  a Vim buffer, and **Alt chords** (which VSCodeVim never receives — see above).
- **Adding an extension?** One line in [`extensions.txt`](extensions.txt), then
  re-run `./install.sh` / `.\install.ps1` (or `update`). Don't hardcode it in a script.
- **Turn Vim off temporarily** without editing anything: `Ctrl+Shift+P` →
  "Extensions: Disable" → Vim.

---

## Next upgrade

The `<leader>` namespace is ported — **now use one group of it for a week.** 34
leader maps exist and none of them are muscle memory yet; pick `g` (git) or `t`
(tests) and force yourself onto it before touching the config again. Knowing
which keys you never reach for is the information that makes the next edit right.

Two things still open, in order:

1. **Port the same namespace to [Zed](../zed/README.md)** — it still has only the
   `g` jumps. Doing all three editors is what makes the muscle memory pay off.
2. **Trim the remaining mouse chrome** (activity bar, breadcrumbs, command
   centre), the same reasoning that removed the minimap — but only once the keys
   above are automatic, or you'll have hidden UI you still need (goal #2).
